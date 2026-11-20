"""CLI: mssql2pg clear | mig | deploy | data | validate"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

import click
import psycopg

from .config import Settings


@click.group()
@click.option("--env-file", type=click.Path(dir_okay=False, path_type=Path), default=Path(".env"),
              show_default=True, help="Konfigurationsdatei")
@click.pass_context
def main(ctx: click.Context, env_file: Path) -> None:
    """Migration gescripteter MS SQL Server Objekte und Daten nach PostgreSQL."""
    try:
        ctx.obj = Settings(_env_file=env_file if env_file.exists() else None)
    except Exception as e:  # noqa: BLE001 – pydantic-Validierungsfehler lesbar ausgeben
        raise click.ClickException(f"Konfiguration ungültig: {e}") from e


def _settings(ctx: click.Context) -> Settings:
    return ctx.obj


@main.command()
@click.pass_context
def clear(ctx: click.Context) -> None:
    """Löscht das Ausgabeverzeichnis (OUT_DIR). overrides/ bleibt unberührt."""
    s = _settings(ctx)
    out = s.out_dir.resolve()
    if out == s.overrides_dir.resolve() or out == Path.cwd().resolve() or out == Path(out.anchor):
        raise click.ClickException(f"OUT_DIR {out} darf nicht gelöscht werden")
    if out.exists():
        shutil.rmtree(out)
        click.echo(f"{out} gelöscht")
    else:
        click.echo(f"{out} existiert nicht")


@main.command()
@click.option("--show", metavar="SCHEMA.NAME", help="Nur dieses Objekt konvertieren und ausgeben (schreibt nichts)")
@click.pass_context
def mig(ctx: click.Context, show: str | None) -> None:
    """Konvertiert die MSSQL-Skripte nach PG-DDL (OUT_DIR + manifest.json)."""
    from . import mig as m

    s = _settings(ctx)
    if show:
        m.prepare(s)
        src = next((x for x in m.sources(s) if x.key == show.lower()), None)
        if src is None:
            raise click.ClickException(f"{show} nicht in {s.mssql_source_dir} gefunden (oder ausgeschlossen)")
        obj = m.convert(src, s.mapping.getdate, m.type_schema(s))
        click.echo(f"-- Status: {obj.status}")
        for msg in obj.messages:
            click.echo(f"-- Hinweis: {msg}")
        click.echo(obj.sql)
        if obj.post_sql:
            click.echo("-- Post:\n" + obj.post_sql)
        return
    m.run_mig(s)


@main.command()
@click.option("--dry-run", is_flag=True, help="Nur Reihenfolge anzeigen")
@click.option("-y", "--yes", is_flag=True, help="Keine Rückfrage vor dem Zurücksetzen der Schemas")
@click.option("--check/--no-check", default=True, show_default=True,
              help="Deployte PL/pgSQL-Funktionen mit plpgsql_check prüfen")
@click.pass_context
def deploy(ctx: click.Context, dry_run: bool, yes: bool, check: bool) -> None:
    """Setzt die verwalteten Schemas zurück und deployt alle Objekte in Abhängigkeitsreihenfolge."""
    from .deploy import run_deploy

    if not run_deploy(_settings(ctx), dry_run=dry_run, yes=yes, check=check):
        sys.exit(1)


@main.command()
@click.pass_context
def check(ctx: click.Context) -> None:
    """Prüft die deployten PL/pgSQL-Funktionen mit plpgsql_check (Report: OUT_DIR/check_report.json)."""
    from .deploy import run_check_only

    if not run_check_only(_settings(ctx)):
        sys.exit(1)


def _table_options(f):
    f = click.option("-t", "--table", "tables", multiple=True, metavar="MUSTER",
                     help="Nur Tabellen schema.tabelle (PG-Namen, fnmatch), mehrfach möglich")(f)
    f = click.option("-x", "--exclude", multiple=True, metavar="MUSTER", help="Tabellen ausschließen (fnmatch)")(f)
    return f


def _existing_tables(dsn: str) -> set[str]:
    with psycopg.connect(dsn) as conn:
        rows = conn.execute(
            "SELECT table_schema || '.' || table_name FROM information_schema.tables WHERE table_type = 'BASE TABLE'"
        ).fetchall()
    return {r[0] for r in rows}


@main.command()
@_table_options
@click.option("-j", "--workers", type=int, help="Parallele Worker (Default: COPY_WORKERS)")
@click.option("--resume", is_flag=True, help="Bereits kopierte Chunks überspringen")
@click.option("--dry-run", is_flag=True, help="Nur Chunk-Planung anzeigen")
@click.option("--no-post", is_flag=True, help="Indizes/FKs/ANALYZE nicht ausführen")
@click.option("--post-only", is_flag=True, help="Nur Indizes/FKs/ANALYZE ausführen")
@click.pass_context
def data(ctx: click.Context, tables: tuple[str, ...], exclude: tuple[str, ...], workers: int | None,
         resume: bool, dry_run: bool, no_post: bool, post_only: bool) -> None:
    """Kopiert die Daten aller Tabellen außer RAW-Schema und Blacklist, danach Indizes/FKs."""
    from .copy import run_copy, select_tables
    from .mig import load_manifest, source_tables
    from .post import run_post

    s = _settings(ctx)
    s.require("pg_dsn", "mssql_conn")
    all_tables = select_tables(source_tables(s), tables, exclude)
    existing = _existing_tables(s.pg_dsn)
    missing = [t.key for t in all_tables if t.key not in existing]
    for k in missing:
        click.echo(f"  übersprungen (nicht deployt): {k}", err=True)
    todo = [t for t in all_tables if t.key in existing]
    if not todo:
        raise click.ClickException("Keine Tabellen zu kopieren")
    dropped: set[str] = set()
    if not post_only:
        dropped = run_copy(todo, s.mssql_conn, s.pg_dsn, workers or s.copy_workers, s.copy_chunk_rows, s.copy_fetch_size,
                 resume, s.mapping.chunk_columns, dry_run)
    if dry_run or no_post:
        return
    manifest = load_manifest(s.out_dir)
    post_sql = {}
    for o in manifest["objects"]:
        if o["type"] == "table" and o.get("post_file"):
            post_sql[f"{o['pg_schema']}.{o['pg_name']}"] = (s.out_dir / o["post_file"]).read_text(encoding="utf-8")
    # FKs von Tabellen außerhalb der Auswahl, die auf kopierte Tabellen zeigen, ebenfalls neu anlegen
    todo_keys = {t.key for t in todo}
    extra = [t for t in source_tables(s) if t.key in dropped - todo_keys and t.key in existing]
    ok = run_post(s.pg_dsn, todo + extra, post_sql)
    if not ok:
        sys.exit(1)


@main.command()
@_table_options
@click.option("-l", "--level", type=click.IntRange(1, 3), default=2, show_default=True,
              help="1=Zeilenzahl, 2=Spaltenaggregate, 3=Zeilen-Hashes")
@click.option("-j", "--workers", type=int, default=4, show_default=True)
@click.option("--raw", "include_raw", is_flag=True, help="Auch Tabellen im RAW-Schema prüfen")
@click.option("--max-diffs", type=int, default=20, show_default=True)
@click.option("--report", type=click.Path(dir_okay=False), help="Markdown-Report schreiben")
@click.pass_context
def validate(ctx: click.Context, tables: tuple[str, ...], exclude: tuple[str, ...], level: int, workers: int,
             include_raw: bool, max_diffs: int, report: str | None) -> None:
    """Vergleicht MSSQL und PostgreSQL tabellenweise."""
    from .copy import select_tables
    from .mig import source_tables
    from .validate import run_validate

    s = _settings(ctx)
    s.require("pg_dsn", "mssql_conn")
    ts = select_tables(source_tables(s, include_raw=include_raw), tables, exclude)
    if not run_validate(ts, lambda t: level, s.mssql_conn, s.pg_dsn, workers, s.copy_fetch_size, max_diffs, report):
        sys.exit(1)


if __name__ == "__main__":
    main()
