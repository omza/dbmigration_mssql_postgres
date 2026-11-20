"""Wendet die SQL-Dateien unter sql/ in definierter Reihenfolge an.

- Verzeichnisse werden alphabetisch abgearbeitet (00_bootstrap, 05_util, 10_tables, ...).
- Innerhalb eines Verzeichnisses: Reihenfolge aus Datei ORDER (eine Datei pro Zeile), sonst alphabetisch.
- Jede Datei läuft in einer eigenen Transaktion; Status (inkl. SHA-256) in _migration.applied.
- Unveränderte, bereits angewendete Dateien werden übersprungen.
"""

from __future__ import annotations

import hashlib
from pathlib import Path

import click
import psycopg

# Läuft nicht beim normalen deploy, sondern erst nach der Datenkopie (energydwh post)
POST_STAGES = {"50_post"}

_TRACKING_DDL = """
CREATE SCHEMA IF NOT EXISTS _migration;
CREATE TABLE IF NOT EXISTS _migration.applied (
    file        text PRIMARY KEY,
    sha256      text NOT NULL,
    applied_at  timestamptz NOT NULL DEFAULT now()
);
"""


def ordered_files(stage_dir: Path) -> list[Path]:
    order_file = stage_dir / "ORDER"
    files = sorted(stage_dir.glob("*.sql"))
    if not order_file.exists():
        return files
    names = [ln.strip() for ln in order_file.read_text(encoding="utf-8").splitlines()
             if ln.strip() and not ln.startswith("#")]
    by_name = {p.name: p for p in files}
    missing = [n for n in names if n not in by_name]
    if missing:
        raise click.ClickException(f"{order_file}: Dateien fehlen: {missing}")
    rest = [p for p in files if p.name not in set(names)]
    return [by_name[n] for n in names] + rest


def stage_dirs(sql_dir: Path, stages: list[str] | None, include_post: bool = False) -> list[Path]:
    dirs = sorted(d for d in sql_dir.iterdir() if d.is_dir())
    if stages:
        unknown = set(stages) - {d.name for d in dirs}
        if unknown:
            raise click.ClickException(f"Unbekannte Stage(s): {sorted(unknown)}")
        return [d for d in dirs if d.name in stages]
    return [d for d in dirs if include_post or d.name not in POST_STAGES]


def deploy(sql_dir: Path, dsn: str, stages: list[str] | None, force: bool = False) -> None:
    with psycopg.connect(dsn, autocommit=True) as conn:
        conn.add_notice_handler(
            lambda d: click.echo(f"      {d.severity}: {d.message_primary}",
                                 err=d.severity not in ("NOTICE", "INFO", "LOG", "DEBUG"))
        )
        conn.execute("SET client_min_messages = notice")
        conn.execute(_TRACKING_DDL)
        applied = dict(conn.execute("SELECT file, sha256 FROM _migration.applied").fetchall())
        n_ok = n_skip = 0
        for d in stage_dirs(sql_dir, stages):
            for f in ordered_files(d):
                rel = f"{d.name}/{f.name}"
                sql = f.read_text(encoding="utf-8")
                digest = hashlib.sha256(sql.encode()).hexdigest()
                if not force and applied.get(rel) == digest:
                    n_skip += 1
                    continue
                try:
                    with conn.transaction():
                        conn.execute(sql)
                        conn.execute(
                            "INSERT INTO _migration.applied(file, sha256) VALUES (%s, %s) "
                            "ON CONFLICT (file) DO UPDATE SET sha256 = EXCLUDED.sha256, applied_at = now()",
                            (rel, digest),
                        )
                except psycopg.Error as e:
                    diag = e.diag
                    pos = f" (Position {diag.statement_position})" if diag.statement_position else ""
                    hint = ""
                    if isinstance(e, psycopg.errors.DuplicateTable) and rel in applied:
                        hint = ("\n  Die Datei wurde nach dem ersten Deploy geändert. Tabellen werden nicht "
                                "automatisch migriert: Änderung per ALTER TABLE in einer neuen Datei abbilden "
                                "oder (Test-DB) neu aufbauen.")
                    raise click.ClickException(
                        f"Fehler in {rel}{pos}: {diag.message_primary or e}{hint}"
                        + (f"\n  Detail: {diag.message_detail}" if diag.message_detail else "")
                        + (f"\n  Hint: {diag.message_hint}" if diag.message_hint else "")
                        + (f"\n  Kontext: {diag.context}" if diag.context else "")
                    ) from e
                click.echo(f"  ok  {rel}")
                n_ok += 1
        click.echo(f"{n_ok} Dateien angewendet, {n_skip} unverändert übersprungen")
