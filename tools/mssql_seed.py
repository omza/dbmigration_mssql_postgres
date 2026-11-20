"""Testwerkzeug: legt die Tabellen aus den MSSQL-Quellskripten in einer (leeren) MSSQL-Dev-Datenbank an
und befüllt sie mit synthetischen Daten – damit `mssql2pg data` und `validate` getestet werden können.

    uv run python tools/mssql_seed.py [--rows 1000] [--big schema.tabelle=50000 ...] [--reset] [--env-file .env]

* Ziel ist die Datenbank aus MSSQL_CONN (.env). Es wird NICHT auf Produktion geprüft – nur für Dev-Instanzen!
* Abbruch, wenn die Datenbank bereits Benutzertabellen enthält. --reset löscht vorher nur die Tabellen,
  die in den Quellskripten vorkommen (Schemas bleiben).
* Angelegt werden nur CREATE TABLE (ohne FKs/Indizes); Schema-Blacklist und RAW-Schema werden ignoriert,
  damit die Quelle vollständig ist.
* Testdaten enthalten Grenzfälle: NULL, Umlaute/€, NUL-Bytes, Datumsgrenzen.
"""

from __future__ import annotations

import argparse
import re
import sys
import time
from datetime import date, datetime, timedelta
from decimal import Decimal
from pathlib import Path

from mssql2pg import mssql, naming
from mssql2pg.config import Settings
from mssql2pg.convert.tables import Column, Table, convert_table
from mssql2pg.source import load_sources
from mssql2pg.typemap import base_kind


def value(col: Column, i: int, in_key: bool):
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
        m = re.search(r"\((\d+),(\d+)\)", pgt)
        p, s = map(int, m.groups()) if m else (18, 0)
        maxint = 10 ** (p - s) - 1
        return Decimal(i % (maxint + 1)) + (Decimal(i % 97) / 100 if s >= 2 else 0)
    if kind == "float":
        return i * 1.1 + 0.3
    if kind == "bool":
        return i % 2 == 0
    if kind == "date":
        return date(2000, 1, 1) + timedelta(days=i % 30000)
    if kind == "ts":
        return datetime(2020, 1, 1) + timedelta(minutes=15 * i, milliseconds=(i % 3) * 3)
    if kind == "time":
        return (datetime(2000, 1, 1) + timedelta(seconds=i % 86400)).time()
    if kind == "bytes":
        return bytes([i % 256, 0, 255])
    if kind == "text":
        m = re.search(r"\((\d+)\)", pgt)
        n = int(m.group(1)) if m else 4000
        s = f"{i}" if in_key else ("Straße Ä Ö Ü ß €" if i % 5 == 0 else f"wert {i}")
        if i % 11 == 0 and not in_key:
            s = "nul\x00byte"
        return s[:n]
    if pgt == "uuid":
        return f"00000000-0000-0000-0000-{i:012d}"
    raise ValueError(f"kein Testwert für {col.name} {col.mssql_type}")


def create_statement(batch: str) -> str:
    """Nur das CREATE TABLE eines Tabellenskripts (FKs/Indizes werden nicht angelegt)."""
    stmt = re.split(r";\s*\n", batch, maxsplit=1)[0]
    # Export enthält teils PK und UNIQUE als CLUSTERED (im Original nicht gleichzeitig möglich)
    return re.sub(r"\bUNIQUE\s+CLUSTERED\b", "UNIQUE NONCLUSTERED", stmt, flags=re.I)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--rows", type=int, default=1000, help="Zeilen je Tabelle")
    ap.add_argument("--big", action="append", default=[], metavar="SCHEMA.TABELLE=N",
                    help="Abweichende Zeilenzahl für einzelne Tabellen (MSSQL-Namen), z.B. zum Testen der Chunks")
    ap.add_argument("--reset", action="store_true", help="Vorhandene Tabellen aus den Quellskripten vorher löschen")
    ap.add_argument("--env-file", type=Path, default=Path(".env"))
    args = ap.parse_args()
    big = {k.lower(): int(v) for k, v in (b.split("=", 1) for b in args.big)}

    s = Settings(_env_file=args.env_file)
    s.require("mssql_conn")
    naming.set_renames(s.mapping.renames)
    srcs = [x for x in load_sources(s.mssql_source_dir, set(), s.mapping.exclude_objects) if x.type == "table"]
    tables: list[tuple[Table, str]] = []
    for src in srcs:
        obj, t = convert_table(src, s.mapping.getdate)
        if t is None:
            print(f"  übersprungen {src.key}: {obj.messages}", file=sys.stderr)
            continue
        tables.append((t, create_statement(src.batches[0])))

    conn = mssql.connect(s.mssql_conn)
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute("SELECT DB_NAME()")
    db = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0")
    existing = cur.fetchone()[0]
    if existing and not args.reset:
        sys.exit(f"Datenbank {db} enthält bereits {existing} Tabellen – Abbruch (--reset löscht die Skript-Tabellen)")
    print(f"Ziel: {db} – {len(tables)} Tabellen, {args.rows} Zeilen je Tabelle")

    if args.reset:
        for t, _ in tables:
            cur.execute(f"IF OBJECT_ID(N'{t.mssql_qualified.replace(chr(39), chr(39) * 2)}', N'U') IS NOT NULL "
                        f"DROP TABLE {t.mssql_qualified}")
    for schema in sorted({t.schema for t, _ in tables}, key=str.lower):
        if schema.lower() != "dbo":
            cur.execute(f"IF SCHEMA_ID(N'{schema}') IS NULL EXEC('CREATE SCHEMA [{schema}]')")

    t0 = time.monotonic()
    for t, ddl in tables:
        cur.execute(ddl)
        key_cols = {c for k in t.keys for c in k.columns}
        cols = [c for c in t.columns if not c.identity]
        n = big.get(f"{t.schema}.{t.name}".lower(), args.rows)
        rows = [tuple(value(c, i, c.pg_name in key_cols) for c in cols) for i in range(1, n + 1)]
        collist = ", ".join(f"[{c.name.replace(']', ']]')}]" for c in cols)
        ph = ", ".join("?" for _ in cols)
        for start in range(0, len(rows), 1000):
            cur.executemany(f"INSERT INTO {t.mssql_qualified} ({collist}) VALUES ({ph})", rows[start:start + 1000])
        print(f"  {t.mssql_qualified}: {n} Zeilen")
    conn.close()
    print(f"fertig in {time.monotonic() - t0:.0f}s")


if __name__ == "__main__":
    main()
