"""Testwerkzeug: baut eine synthetische EnergyDWH-Quelldatenbank auf einem MSSQL-Testserver.

    uv run python tests/mssql_seed.py "SERVER=localhost,51433;UID=sa;PWD=...;Encrypt=yes;TrustServerCertificate=yes" [rows]

Legt DB EnergyDWH an, alle Schemas + Tabellen aus energydwh-main/Tables (ohne FKs/Indizes),
und befüllt jede Tabelle mit `rows` synthetischen Zeilen inkl. Grenzfällen.
"""

from __future__ import annotations

import re
import sys
from datetime import date, datetime, timedelta
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from energydwh import mssql  # noqa: E402
from energydwh.tables import load_tables  # noqa: E402
from energydwh.typemap import base_kind  # noqa: E402


def value(col, i: int, in_key: bool):
    if col.identity:
        return None
    if col.nullable and not in_key and i % 7 == 3:
        return None
    t = col.mssql_type.lower()
    pgt = col.pg_type
    kind = base_kind(pgt)
    if "tinyint" in t:
        return i % 256
    if "smallint" in t:
        return i % 32000
    if kind == "int":
        return i
    if kind == "numeric":
        p, s = map(int, re.search(r"\((\d+),(\d+)\)", pgt).groups())
        maxint = 10 ** (p - s) - 1
        return Decimal(i % (maxint + 1)) + (Decimal(i % 97) / 100 if s >= 2 else 0)
    if kind == "float":
        return i * 1.1 + 0.3
    if kind == "bool":
        return i % 2 == 0
    if kind == "date":
        return date(2000, 1, 1) + timedelta(days=i)
    if kind == "ts":
        return datetime(2020, 1, 1) + timedelta(minutes=15 * i, milliseconds=(i % 3) * 3)
    if kind == "bytes":
        return bytes([i % 256, 0, 255])
    if kind == "text":
        m = re.search(r"\((\d+)\)", pgt)
        n = int(m.group(1)) if m else 4000
        s = f"{i}" if in_key else ("Straße Ä Ö Ü ß €" if i % 5 == 0 else f"wert {i}")
        if i % 11 == 0 and not in_key:
            s = "nul\x00byte"
        if "char(" in pgt and not pgt.startswith("varchar"):
            s = s[:n]
        return s[:n]
    raise ValueError(f"kein Testwert für {col.name} {col.mssql_type}")


def main(conn_str: str, rows: int) -> None:
    conn = mssql.connect(conn_str)
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute("IF DB_ID('EnergyDWH') IS NOT NULL BEGIN ALTER DATABASE EnergyDWH SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE EnergyDWH; END")
    cur.execute("CREATE DATABASE EnergyDWH COLLATE Latin1_General_CI_AS")
    cur.execute("USE EnergyDWH")
    tables = load_tables(ROOT / "energydwh-main" / "Tables")
    for s in sorted({t.schema for t in tables}):
        if s.lower() != "dbo":
            cur.execute(f"CREATE SCHEMA [{s}]")
    for t in tables:
        ddl = t.source.read_text(encoding="utf-8-sig")
        create = re.split(r";\s*\n", ddl)[0].replace("UNIQUE CLUSTERED", "UNIQUE NONCLUSTERED")
        cur.execute(create)
        key_cols = {c for k in t.keys for c, _ in k.columns}
        cols = [c for c in t.columns if not c.identity]
        n = rows * 3 if t.name == "kalender" else rows
        data = [tuple(value(c, i, c.name in key_cols) for c in cols) for i in range(1, n + 1)]
        collist = ", ".join(f"[{c.name}]" for c in cols)
        ph = ", ".join("?" for _ in cols)
        cur.executemany(f"INSERT INTO {t.mssql_qualified} ({collist}) VALUES ({ph})", data)
        print(f"{t.mssql_qualified}: {n} Zeilen")
    conn.close()


if __name__ == "__main__":
    main(sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 100)
