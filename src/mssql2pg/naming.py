"""Bezeichner-Regeln MSSQL -> PostgreSQL.

Alles lowercase. Quoting nur, wenn der Name kein regulärer PG-Bezeichner ist
(Sonderzeichen, Leerzeichen, führende Ziffer, reserviertes Wort).
Umlaute/ß sind in unquotierten PG-Bezeichnern erlaubt.
Umbenennungen (z.B. Namen > 63 Bytes) kommen aus mapping.yml -> set_renames().
"""

from __future__ import annotations

import re

PG_MAX_IDENT_BYTES = 63

_RENAMES: dict[str, str] = {}


def set_renames(renames: dict[str, str]) -> None:
    _RENAMES.clear()
    _RENAMES.update({k.lower(): v for k, v in renames.items()})


# PostgreSQL-Schlüsselwörter, die als Bezeichner gequotet werden müssen
# (Kategorie "reserved" und "reserved (can be function or type)", PG-Doku Appendix C).
PG_RESERVED = frozenset("""
all analyse analyze and any array as asc asymmetric authorization between bigint binary
bit boolean both case cast char character check coalesce collate collation column
concurrently constraint create cross current_catalog current_date current_role
current_schema current_time current_timestamp current_user dec decimal default
deferrable desc distinct do else end except exists extract false fetch float for
foreign freeze from full grant greatest group grouping having ilike in initially
inner inout int integer intersect interval into is isnull join json json_array
json_arrayagg json_exists json_object json_objectagg json_query json_scalar
json_serialize json_table json_value lateral leading least left like limit
localtime localtimestamp merge_action national natural nchar none normalize not
notnull null nullif numeric offset on only or order out outer overlaps overlay
placing position precision primary real references returning right row select
session_user setof similar smallint some substring symmetric system_user table
tablesample then time timestamp to trailing treat trim true union unique user using
values varchar variadic verbose when where window with xmlattributes xmlconcat
xmlelement xmlexists xmlforest xmlnamespaces xmlparse xmlpi xmlroot xmlserialize
xmltable
""".split())

_REGULAR = re.compile(r"^[a-zäöüß_][a-z0-9äöüß_$]*$")


def unbracket(name: str) -> str:
    n = name.strip()
    if n.startswith("[") and n.endswith("]"):
        n = n[1:-1].replace("]]", "]")
    elif n.startswith('"') and n.endswith('"'):
        n = n[1:-1].replace('""', '"')
    return n


def pg_name(name: str) -> str:
    """Original-MSSQL-Bezeichner (mit/ohne Klammern) -> PG-Name (lowercase, unquotiert)."""
    n = unbracket(name).lower()
    n = _RENAMES.get(n, n)
    if len(n.encode("utf-8")) > PG_MAX_IDENT_BYTES:
        raise ValueError(
            f"Bezeichner > {PG_MAX_IDENT_BYTES} Bytes, bitte in mapping.yml unter 'renames' aufnehmen: {name!r}"
        )
    return n


def needs_quoting(n: str) -> bool:
    return not _REGULAR.match(n) or n in PG_RESERVED


def quote(n: str) -> str:
    """PG-Name (bereits lowercase) -> SQL-Bezeichner, nur bei Bedarf gequotet."""
    if needs_quoting(n):
        return '"' + n.replace('"', '""') + '"'
    return n


def ident(name: str) -> str:
    """Original-MSSQL-Bezeichner -> fertig quotierter PG-Bezeichner."""
    return quote(pg_name(name))


def qualified(schema: str, obj: str) -> str:
    return f"{ident(schema)}.{ident(obj)}"
