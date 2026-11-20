"""Statische Prüfung der deployten PL/pgSQL-Funktionen mit der Extension plpgsql_check.

PostgreSQL prüft PL/pgSQL-Rümpfe beim CREATE FUNCTION nur syntaktisch. plpgsql_check findet
Fehler, die sonst erst zur Laufzeit auftreten (unbekannte Spalten/Tabellen, Typkonflikte, ...).

Temp-Tabellen (tmp_*) existieren erst zur Laufzeit; Meldungen dazu gelten als "nicht prüfbar".
"""

from __future__ import annotations

import re

import click
import psycopg

EXTENSION = "plpgsql_check"
_TEMP_RE = re.compile(r'relation "(pg_temp\.)?tmp_\w+" does not exist')

# Meldungsstufen von plpgsql_check, die als Fehler zählen
ERROR_LEVELS = {"error"}


def ensure_extension(conn: psycopg.Connection) -> str | None:
    """Extension anlegen. -> None wenn verfügbar, sonst Begründung."""
    row = conn.execute("SELECT installed_version FROM pg_available_extensions WHERE name = %s",
                       (EXTENSION,)).fetchone()
    if row is None:
        return f"Extension {EXTENSION} ist auf dem Server nicht installiert (Paket postgresql-<ver>-plpgsql-check)"
    if row[0] is None:
        try:
            with conn.transaction():
                conn.execute(f"CREATE EXTENSION IF NOT EXISTS {EXTENSION}")
        except psycopg.Error as e:
            return f"CREATE EXTENSION {EXTENSION} nicht möglich: {str(e).strip().splitlines()[0]}"
    return None


def check_functions(conn: psycopg.Connection, functions: list[tuple[str, str, str]]) -> dict[str, dict]:
    """functions: (key, pg_schema, pg_name) -> {key: {"errors": [...], "warnings": [...], "unchecked": [...]}}"""
    result: dict[str, dict] = {}
    for key, schema, name in functions:
        oids = conn.execute(
            "SELECT p.oid FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace "
            "JOIN pg_language l ON l.oid = p.prolang "
            "WHERE n.nspname = %s AND p.proname = %s AND l.lanname = 'plpgsql'",
            (schema, name)).fetchall()
        if not oids:
            continue          # nicht deployt oder keine PL/pgSQL-Funktion
        entry = {"errors": [], "warnings": [], "unchecked": []}
        for (oid,) in oids:
            try:
                with conn.transaction():
                    rows = conn.execute(
                        "SELECT level, message, lineno, statement, sqlstate, detail, hint "
                        "FROM plpgsql_check_function_tb(%s, fatal_errors := false, extra_warnings := false)",
                        (oid,)).fetchall()
            except psycopg.Error as e:
                entry["errors"].append(f"Prüfung abgebrochen: {str(e).strip().splitlines()[0]}")
                continue
            for level, message, lineno, statement, _sqlstate, detail, hint in rows:
                text = f"Zeile {lineno} ({statement}): {message}" if lineno else message
                if detail:
                    text += f" – {detail}"
                if hint:
                    text += f" (Hinweis: {hint})"
                if _TEMP_RE.search(message or ""):
                    entry["unchecked"].append(text)
                elif level in ERROR_LEVELS:
                    entry["errors"].append(text)
                else:
                    entry["warnings"].append(text)
        result[key] = entry
    return result


def report(result: dict[str, dict]) -> None:
    n_err = sum(1 for r in result.values() if r["errors"])
    n_unchecked = sum(1 for r in result.values() if r["unchecked"] and not r["errors"])
    click.echo(f"\nplpgsql_check: {len(result)} Funktionen geprüft, {n_err} mit Fehlern, "
               f"{n_unchecked} nur teilweise prüfbar (Temp-Tabellen)")
    shown = 0
    for key, r in sorted(result.items()):
        for e in r["errors"]:
            if shown < 40:
                click.echo(f"  CHECK {key}: {e}", err=True)
            shown += 1
    if shown > 40:
        click.echo(f"  ... {shown - 40} weitere Meldungen im Report", err=True)
