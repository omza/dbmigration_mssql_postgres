"""Gemeinsame Fixtures. Integrationstests laufen nur, wenn Test-DBs per ENV gesetzt sind:

    export TEST_MSSQL_CONN='SERVER=localhost,51433;DATABASE=EnergyDWH;UID=sa;PWD=...;Encrypt=yes;TrustServerCertificate=yes'
    export TEST_PG_DSN='postgresql://postgres:test@localhost:55432/energydwh'

ACHTUNG: Die Tests legen Objekte in beiden Datenbanken an bzw. ändern Daten – nur Testinstanzen verwenden!
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "energydwh-main"
sys.path.insert(0, str(ROOT / "src"))


@pytest.fixture(scope="session")
def mssql_conn():
    conn_str = os.environ.get("TEST_MSSQL_CONN")
    if not conn_str:
        pytest.skip("TEST_MSSQL_CONN nicht gesetzt")
    from energydwh import mssql

    conn = mssql.connect(conn_str)
    conn.autocommit = True
    yield conn
    conn.close()


@pytest.fixture(scope="session")
def pg_conn():
    dsn = os.environ.get("TEST_PG_DSN")
    if not dsn:
        pytest.skip("TEST_PG_DSN nicht gesetzt")
    import psycopg

    from energydwh.deploy import deploy

    deploy(ROOT / "sql", dsn, None)
    with psycopg.connect(dsn, autocommit=True) as conn:
        yield conn


def _norm(v):
    from decimal import Decimal

    if isinstance(v, str):
        return v.rstrip(" ")
    if isinstance(v, Decimal):
        return v.normalize()
    return v


def rows_ms(conn, sql: str, *params) -> list[tuple]:
    cur = conn.cursor()
    cur.execute(sql, params) if params else cur.execute(sql)
    if cur.description is None:
        return []
    return [tuple(_norm(v) for v in r) for r in cur.fetchall()]


def rows_pg(conn, sql: str, params=None) -> list[tuple]:
    cur = conn.execute(sql, params)
    if cur.description is None:
        return []
    return [tuple(_norm(v) for v in r) for r in cur.fetchall()]


def both(ms_conn, pg_conn, sql: str) -> None:
    """Führt ein dialektneutrales Statement auf beiden Seiten aus (Testdaten anpassen)."""
    ms_conn.cursor().execute(sql)
    pg_conn.execute(sql)


def assert_same_rows(a: list[tuple], b: list[tuple]) -> None:
    from collections import Counter

    ca, cb = Counter(a), Counter(b)
    only_ms = list((ca - cb).elements())[:10]
    only_pg = list((cb - ca).elements())[:10]
    assert not only_ms and not only_pg, f"nur MSSQL: {only_ms}\nnur PG: {only_pg}"


def mssql_create(conn, relpath: str) -> None:
    """Legt ein Original-T-SQL-Objekt aus energydwh-main im MSSQL-Testserver (neu) an."""
    path = SRC / relpath
    sql = path.read_text(encoding="utf-8-sig")
    name = path.name.split(".")[0] + "." + path.name.split(".")[1]
    kind = {"UserDefinedFunction": "FUNCTION", "StoredProcedure": "PROCEDURE", "View": "VIEW"}[path.name.split(".")[2]]
    cur = conn.cursor()
    cur.execute(f"IF OBJECT_ID('{name}') IS NOT NULL DROP {kind} {name}")
    for batch in re.split(r"^\s*GO\s*$", sql, flags=re.M | re.I):
        if batch.strip():
            cur.execute(batch)
