"""Nach der Datenkopie: Indizes, FKs (NOT VALID + einzeln validieren), Identity-Reset, ANALYZE."""

from __future__ import annotations

import click
import psycopg

from .convert.tables import Table, render_identity_reset
from .deploy import _err

# Validiert alle NOT-VALID-FKs einzeln. Verletzungen brechen nicht ab, sondern werden als
# WARNING gemeldet (FK bleibt NOT VALID, gilt aber für neue Daten). Grund: In MSSQL können
# FKs "untrusted" (WITH NOCHECK) sein – das ist im Export nicht sichtbar.
VALIDATE_FKS_SQL = """DO $$
DECLARE
    r record;
    n_ok int := 0;
    n_bad int := 0;
BEGIN
    FOR r IN
        SELECT c.conrelid::regclass AS tbl, c.conname
        FROM pg_constraint c
        JOIN pg_namespace n ON n.oid = c.connamespace
        WHERE c.contype = 'f' AND NOT c.convalidated AND n.nspname NOT LIKE 'pg\\_%'
        ORDER BY 1, 2
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE %s VALIDATE CONSTRAINT %I', r.tbl, r.conname);
            n_ok := n_ok + 1;
        EXCEPTION WHEN foreign_key_violation THEN
            n_bad := n_bad + 1;
            RAISE WARNING 'FK % auf % verletzt (bleibt NOT VALID): %', r.conname, r.tbl, SQLERRM;
        END;
    END LOOP;
    RAISE NOTICE 'FK-Validierung: % ok, % verletzt', n_ok, n_bad;
END
$$;
"""


def run_post(pg_dsn: str, tables: list[Table], post_sql: dict[str, str]) -> bool:
    """post_sql: Tabellenschlüssel (pg_schema.pg_table) -> SQL aus out/post/."""
    errors = 0

    def notice(diag) -> None:
        msg = diag.message_primary or ""
        if msg.endswith("does not exist, skipping"):      # DROP ... IF EXISTS
            return
        click.echo(f"  {diag.severity}: {msg}")

    with psycopg.connect(pg_dsn, autocommit=True) as conn:
        conn.add_notice_handler(notice)
        # Indizes zuerst, dann FKs (FKs brauchen die Unique-Indizes der Zieltabellen)
        stmts = {t.key: [x.strip() for x in post_sql.get(t.key, "").split(";\n") if x.strip()] for t in tables}

        def is_index(stmt: str) -> bool:
            return stmt.upper().startswith("CREATE") and " INDEX " in f" {stmt.upper()} "

        for label, want_index in (("Indizes", True), ("Foreign Keys", False)):
            click.echo(f"{label} ...")
            for t in tables:
                for stmt in stmts[t.key]:
                    if is_index(stmt) != want_index:
                        continue
                    try:
                        with conn.transaction():
                            conn.execute(stmt.rstrip(";"))
                    except psycopg.Error as e:
                        errors += 1
                        click.echo(f"  FEHLER {t.key}: {_err(e)}", err=True)
        click.echo("Identity-Reset ...")
        for t in tables:
            sql = render_identity_reset(t)
            if sql:
                try:
                    conn.execute(sql)
                except psycopg.Error as e:
                    errors += 1
                    click.echo(f"  FEHLER {t.key}: {_err(e)}", err=True)
        click.echo("FK-Validierung ...")
        conn.execute(VALIDATE_FKS_SQL)
        click.echo("ANALYZE ...")
        for t in tables:
            conn.execute(f"ANALYZE {t.pg_qualified}")
    return errors == 0
