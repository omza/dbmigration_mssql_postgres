"""Kommandozeile: energydwh <kommando>."""

from __future__ import annotations

from pathlib import Path

import click

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SRC = ROOT / "energydwh-main"
DEFAULT_SQL = ROOT / "sql"


@click.group()
def main() -> None:
    """Migration EnergyDWH MSSQL -> PostgreSQL."""


@main.command()
@click.option("--src", type=click.Path(path_type=Path), default=DEFAULT_SRC, show_default=True)
@click.option("--out", type=click.Path(path_type=Path), default=DEFAULT_SQL, show_default=True)
def generate(src: Path, out: Path) -> None:
    """Erzeugt sql/00_bootstrap, sql/10_tables, sql/50_post aus den MSSQL-Skripten."""
    from .generate import generate as _gen

    written, skipped = _gen(src, out)
    click.echo(f"{len(written)} Dateien geschrieben, {len(skipped)} manuell gepflegte übersprungen")
    for p in skipped:
        click.echo(f"  übersprungen: {p.relative_to(out)}")


@main.command()
@click.option("--sql", "sql_dir", type=click.Path(path_type=Path), default=DEFAULT_SQL, show_default=True)
@click.option("--dsn", envvar="PG_DSN", required=True, help="PostgreSQL-DSN (oder ENV PG_DSN)")
@click.option("--stage", "stages", multiple=True,
              help="Nur diese Verzeichnisse anwenden (z.B. 10_tables). Default: alle außer 50_post")
@click.option("--force", is_flag=True, help="Auch bereits angewendete, unveränderte Dateien erneut ausführen")
def deploy(sql_dir: Path, dsn: str, stages: tuple[str, ...], force: bool) -> None:
    """Wendet sql/ in Reihenfolge auf die PG-Datenbank an (je Datei eine Transaktion)."""
    from .deploy import deploy as _deploy

    _deploy(sql_dir, dsn, stages or None, force)


def _load_config(path: Path | None) -> dict:
    import tomllib

    p = path or ROOT / "migration.toml"
    if not p.exists():
        return {}
    with p.open("rb") as f:
        return tomllib.load(f)


_table_opts = [
    click.option("--table", "-t", "patterns", multiple=True,
                 help="Nur Tabellen passend zu Muster (schema.tabelle, Wildcards), mehrfach möglich"),
    click.option("--exclude", "-x", "excludes", multiple=True, help="Tabellen ausschließen (Muster)"),
    click.option("--src", type=click.Path(path_type=Path), default=DEFAULT_SRC, show_default=True),
    click.option("--config", type=click.Path(path_type=Path), default=None,
                 help="TOML-Konfiguration (Default: ./migration.toml, falls vorhanden)"),
    click.option("--mssql", "mssql_conn", envvar="MSSQL_CONN", required=True,
                 help="MSSQL-Connection-String (oder ENV MSSQL_CONN)"),
    click.option("--dsn", envvar="PG_DSN", required=True, help="PostgreSQL-DSN (oder ENV PG_DSN)"),
]


def table_options(f):
    for opt in reversed(_table_opts):
        f = opt(f)
    return f


@main.command()
@table_options
@click.option("--workers", "-j", type=int, default=None, help="Parallele Prozesse (Default aus Config bzw. 6)")
@click.option("--chunk-rows", type=int, default=None, help="Zeilen pro Chunk (Default 5.000.000)")
@click.option("--fetch-size", type=int, default=20_000, show_default=True)
@click.option("--resume", is_flag=True, help="Bereits kopierte Chunks überspringen")
@click.option("--dry-run", is_flag=True, help="Nur Chunk-Plan anzeigen")
def copy(patterns, excludes, src, config, mssql_conn, dsn, workers, chunk_rows, fetch_size, resume, dry_run):
    """Kopiert Daten MSSQL -> PG (vorher deploy, danach post)."""
    from .copy import run_copy, select_tables
    from .tables import load_tables

    cfg = _load_config(config).get("copy", {})
    tables = select_tables(load_tables(src / "Tables"), patterns, excludes + tuple(cfg.get("exclude", [])))
    run_copy(
        tables, mssql_conn, dsn,
        workers=workers or cfg.get("workers", 6),
        chunk_rows=chunk_rows or cfg.get("chunk_rows", 5_000_000),
        fetch_size=fetch_size,
        resume=resume,
        overrides={k.lower(): v for k, v in cfg.get("chunk_column", {}).items()},
        dry_run=dry_run,
    )


@main.command()
@table_options
@click.option("--level", "-l", type=click.IntRange(1, 3), default=None,
              help="Prüfstufe für alle Tabellen. Default: 3 für admin/core/mart_*/stage, 2 für den Rest")
@click.option("--workers", "-j", type=int, default=4, show_default=True)
@click.option("--fetch-size", type=int, default=20_000, show_default=True)
@click.option("--max-diffs", type=int, default=50, show_default=True, help="Max. gemeldete Zeilen je Tabelle")
@click.option("--report", type=click.Path(), default=None, help="Markdown-Report schreiben")
def validate(patterns, excludes, src, config, mssql_conn, dsn, level, workers, fetch_size, max_diffs, report):
    """Vergleicht MSSQL und PG (Zeilen, Spaltenaggregate, Zeileninhalte). Exit 1 bei Abweichungen."""
    from .copy import select_tables
    from .tables import load_tables
    from .validate import run_validate

    cfg = _load_config(config).get("validate", {})
    full_schemas = tuple(cfg.get("full_compare_schemas", ["admin", "core", "mart_*", "stage", "dbo", "dwh"]))
    tables = select_tables(load_tables(src / "Tables"), patterns, excludes + tuple(cfg.get("exclude", [])))

    import fnmatch

    def level_for(t):
        if level:
            return level
        return 3 if any(fnmatch.fnmatch(t.pg_schema, s) for s in full_schemas) else 2

    if not run_validate(tables, level_for, mssql_conn, dsn, workers, fetch_size, max_diffs, report):
        raise SystemExit(1)


@main.command()
@click.option("--sql", "sql_dir", type=click.Path(path_type=Path), default=DEFAULT_SQL, show_default=True)
@click.option("--dsn", envvar="PG_DSN", required=True, help="PostgreSQL-DSN (oder ENV PG_DSN)")
def post(sql_dir: Path, dsn: str) -> None:
    """Nach der Datenkopie: Indizes, Foreign Keys, Identity-Sequenzen, ANALYZE."""
    import psycopg

    from .deploy import deploy as _deploy

    _deploy(sql_dir, dsn, ["50_post"], force=True)
    with psycopg.connect(dsn, autocommit=True) as conn:
        conn.execute("ANALYZE")
    click.echo("ANALYZE ok")


if __name__ == "__main__":
    main()
