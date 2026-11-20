"""Datentyp-Mapping MSSQL -> PostgreSQL."""

from __future__ import annotations

import re

_TYPE_RE = re.compile(
    r"^\s*(?:\[?sys\]?\.)?\[?(?P<name>[A-Za-z0-9_]+)\]?\s*(?:\(\s*(?P<args>[^)]*)\))?\s*$"
)

# Typen ohne Parameter
_SIMPLE = {
    "bigint": "bigint",
    "int": "integer",
    "integer": "integer",
    "smallint": "smallint",
    "tinyint": "smallint",
    "bit": "boolean",
    "real": "real",
    "float": "double precision",
    "money": "numeric(19,4)",
    "smallmoney": "numeric(10,4)",
    "date": "date",
    "datetime": "timestamp(3)",
    "smalldatetime": "timestamp(0)",
    "datetime2": "timestamp",
    "datetimeoffset": "timestamptz",
    "time": "time",
    "text": "text",
    "ntext": "text",
    "image": "bytea",
    "sysname": "varchar(128)",
    "uniqueidentifier": "uuid",
    "xml": "xml",
}


def pg_type(mssql: str) -> str:
    """'[sys].[datetime]', 'sys.bigint', 'varchar(MAX)', 'decimal(13,2)' ... -> PG-Typ."""
    m = _TYPE_RE.match(mssql)
    if not m:
        raise ValueError(f"Unbekannte Typ-Syntax: {mssql!r}")
    name = m["name"].lower()
    args = (m["args"] or "").replace(" ", "")
    if name in ("varchar", "nvarchar", "char", "nchar", "varbinary", "binary"):
        if name in ("varbinary", "binary"):
            return "bytea"
        if args.lower() == "max":
            return "text"
        if not args:
            return "varchar(1)" if name.endswith("varchar") else "char(1)"
        return f"{'char' if name in ('char', 'nchar') else 'varchar'}({args})"
    if name in ("decimal", "numeric"):
        return f"numeric({args})" if args else "numeric(18,0)"
    if name == "float" and args:
        return "real" if int(args) <= 24 else "double precision"
    if name in ("datetime2", "time") and args:
        return f"{'timestamp' if name == 'datetime2' else 'time'}({min(int(args), 6)})"
    if name in _SIMPLE:
        return _SIMPLE[name]
    raise ValueError(f"Kein Mapping für MSSQL-Typ {mssql!r}")


def base_kind(pg: str) -> str:
    """Grobe Typklasse für Kopie/Validierung: int, numeric, float, text, bool, date, ts, bytes, other."""
    p = pg.split("(")[0].strip()
    return {
        "bigint": "int", "integer": "int", "smallint": "int",
        "numeric": "numeric",
        "real": "float", "double precision": "float",
        "varchar": "text", "char": "text", "text": "text",
        "boolean": "bool",
        "date": "date",
        "timestamp": "ts", "timestamptz": "ts", "time": "time",
        "bytea": "bytes",
    }.get(p, "other")
