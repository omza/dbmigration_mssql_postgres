"""Bezeichner-Regeln MSSQL -> PostgreSQL.

Entscheidung: alles lowercase. Quoting nur, wenn der Name kein regulärer
PG-Bezeichner ist (Sonderzeichen, Leerzeichen, führende Ziffer, reserviertes Wort).
Umlaute/ß sind in unquotierten PG-Bezeichnern erlaubt.
"""

from __future__ import annotations

import re

PG_MAX_IDENT_BYTES = 63

# Explizite Umbenennungen für Bezeichner, die in PG nicht 1:1 gehen (z.B. > 63 Bytes).
# Schlüssel: Originalname lowercase. Jede Umbenennung muss in docs/talend_umstellung.md stehen.
RENAMES: dict[str, str] = {
    "abgleich_mit_rainer_hoffs_liste_ob_vorhanden_nv_bei_ihm_nicht_geführt":
        "abgleich_rainer_hoffs_liste_nv_bei_ihm_nicht_geführt",
}

# Datenbanknamen, die in 3-/4-teiligen Namen entfallen (gleiche Datenbank).
LOCAL_DATABASES = {"energydwh"}

# PostgreSQL-Schlüsselwörter, die als Spalten-/Tabellenname gequotet werden müssen
# (Kategorie "reserved" und "reserved (can be function or type)" laut PG-Doku, Appendix C).
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


def pg_name(name: str) -> str:
    """Original-MSSQL-Bezeichner (ohne Klammern) -> PG-Name (lowercase, unquotiert)."""
    n = name.strip()
    if n.startswith("[") and n.endswith("]"):
        n = n[1:-1].replace("]]", "]")
    n = n.lower()
    n = RENAMES.get(n, n)
    if len(n.encode("utf-8")) > PG_MAX_IDENT_BYTES:
        raise ValueError(
            f"Bezeichner > {PG_MAX_IDENT_BYTES} Bytes, bitte in naming.RENAMES aufnehmen: {name!r}"
        )
    return n


def needs_quoting(n: str) -> bool:
    return not _REGULAR.match(n) or n in PG_RESERVED


def quote(n: str) -> str:
    """PG-Name (bereits lowercase) -> SQL-Literal für Bezeichner."""
    if needs_quoting(n):
        return '"' + n.replace('"', '""') + '"'
    return n


def ident(name: str) -> str:
    """Original-MSSQL-Bezeichner -> fertig quotierter PG-Bezeichner."""
    return quote(pg_name(name))


def qualified(schema: str, obj: str) -> str:
    return f"{ident(schema)}.{ident(obj)}"
