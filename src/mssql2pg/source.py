"""Liest den täglichen SSMS-Export der MSSQL-Objekte.

Erwartetes Layout (Unterverzeichnisse beliebig tief):
  <schema>.<name>.Tables.sql | .Table.sql
  <schema>.<name>.View.sql
  <schema>.<name>.StoredProcedure.sql
  <schema>.<name>.UserDefinedFunction.sql
"""

from __future__ import annotations

import fnmatch
import re
from pathlib import Path

from .model import SourceObject

SUFFIXES = {
    "tables": "table",
    "table": "table",
    "view": "view",
    "storedprocedure": "procedure",
    "userdefinedfunction": "function",
}

_GO_RE = re.compile(r"^[ \t]*GO[ \t]*(?:--[^\n]*)?$", re.M | re.I)


def read_text(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        return raw.decode("utf-16")
    try:
        return raw.decode("utf-8-sig")
    except UnicodeDecodeError:
        return raw.decode("cp1252")


def split_batches(sql: str) -> list[str]:
    return [b.strip("\n") for b in _GO_RE.split(sql) if b.strip()]


def classify(path: Path) -> tuple[str, str, str] | None:
    """Dateiname -> (schema, name, typ) oder None, wenn kein bekanntes Objektskript."""
    parts = path.name.split(".")
    if len(parts) < 4 or parts[-1].lower() != "sql":
        return None
    typ = SUFFIXES.get(parts[-2].lower())
    if typ is None:
        return None
    return parts[0], ".".join(parts[1:-2]), typ


def load_sources(src_dir: Path, blacklist: set[str], exclude: list[str],
                 skip_schemas: set[str] = frozenset()) -> list[SourceObject]:
    """Alle Objekte aus src_dir, ohne Blacklist-Schemas, exclude-Muster und skip_schemas."""
    if not src_dir.is_dir():
        raise FileNotFoundError(f"MSSQL_SOURCE_DIR existiert nicht: {src_dir}")
    out: list[SourceObject] = []
    for p in sorted(src_dir.rglob("*.sql")):
        c = classify(p)
        if c is None:
            continue
        schema, name, typ = c
        if schema.lower() in blacklist or schema.lower() in skip_schemas:
            continue
        key = f"{schema}.{name}".lower()
        if any(fnmatch.fnmatchcase(key, pat) for pat in exclude):
            continue
        out.append(SourceObject(schema, name, typ, p, split_batches(read_text(p))))
    return out
