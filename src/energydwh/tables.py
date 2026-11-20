"""Parser für die exportierten MSSQL-Tabellenskripte (energydwh-main/Tables) + PG-Renderer.

Das Exportformat ist maschinell erzeugt und sehr regelmäßig. Der Parser ist bewusst
strikt: Alles, was er nicht kennt, führt zu einem Fehler statt zu stillem Datenverlust.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from .naming import ident, pg_name, qualified, quote
from .typemap import pg_type

# Objekte, die nicht migriert werden (SSMS-Diagrammunterstützung)
EXCLUDED_TABLES = {("dbo", "sysdiagrams")}

_NAME = r"\[((?:[^\]]|\]\])+)\]"
_QNAME = rf"{_NAME}\.{_NAME}"

_CREATE_RE = re.compile(rf"^CREATE TABLE {_QNAME}\s*\((?P<body>.*)\)$", re.S)
_COL_RE = re.compile(
    rf"^{_NAME}\s+(?P<type>\[sys\]\.\[[a-z0-9]+\]|[a-z]+(?:\([^)]*\))?)"
    r"(?:\s+COLLATE\s+\w+)?"
    r"(?:\s+IDENTITY\((?P<seed>-?\d+),(?P<incr>-?\d+)\))?"
    rf"(?:\s+CONSTRAINT\s+{_NAME}\s+DEFAULT\s+(?P<default>.+?))?"
    r"\s+(?P<null>NOT NULL|NULL)$",
    re.I,
)
_KEY_RE = re.compile(
    rf"^CONSTRAINT\s+{_NAME}\s+(?P<kind>PRIMARY KEY|UNIQUE)(?:\s+(?:NON)?CLUSTERED)?\s*\((?P<cols>.*)\)$",
    re.I,
)
_FK_RE = re.compile(
    rf"^ALTER TABLE {_QNAME}\s+ADD CONSTRAINT {_NAME}\s+FOREIGN KEY\s*\((?P<cols>[^)]*)\)\s+"
    rf"REFERENCES {_NAME}\.{_NAME}\s*\((?P<refcols>[^)]*)\)$",
    re.I,
)
_IDX_RE = re.compile(
    rf"^CREATE (?P<unique>UNIQUE )?(?:NON)?CLUSTERED INDEX {_NAME}\s+ON {_QNAME}\s*\((?P<cols>[^)]*)\)"
    r"(?:\s+INCLUDE\s*\((?P<incl>[^)]*)\))?$",
    re.I,
)


@dataclass
class Column:
    name: str                 # Originalname MSSQL
    mssql_type: str
    nullable: bool
    identity: bool = False
    default: str | None = None   # Original-Default-Ausdruck (MSSQL)

    @property
    def pg_name(self) -> str:
        return pg_name(self.name)

    @property
    def pg_type(self) -> str:
        return pg_type(self.mssql_type)


@dataclass
class Key:
    name: str
    kind: str                 # 'PRIMARY KEY' | 'UNIQUE'
    columns: list[tuple[str, str]]  # (spalte, ASC|DESC)


@dataclass
class ForeignKey:
    name: str
    columns: list[str]
    ref_schema: str
    ref_table: str
    ref_columns: list[str]


@dataclass
class Index:
    name: str
    unique: bool
    columns: list[tuple[str, str]]
    include: list[str]


@dataclass
class Table:
    schema: str
    name: str
    columns: list[Column] = field(default_factory=list)
    keys: list[Key] = field(default_factory=list)
    fks: list[ForeignKey] = field(default_factory=list)
    indexes: list[Index] = field(default_factory=list)
    source: Path | None = None

    @property
    def pg_schema(self) -> str:
        return pg_name(self.schema)

    @property
    def pg_table(self) -> str:
        return pg_name(self.name)

    @property
    def pg_qualified(self) -> str:
        return qualified(self.schema, self.name)

    @property
    def mssql_qualified(self) -> str:
        return f"[{self.schema}].[{self.name}]"

    @property
    def primary_key(self) -> Key | None:
        return next((k for k in self.keys if k.kind == "PRIMARY KEY"), None)


# --------------------------------------------------------------------------- Parser


def _unbracket(s: str) -> str:
    return s.strip()[1:-1].replace("]]", "]") if s.strip().startswith("[") else s.strip()


def _split_top(s: str, sep: str = ",") -> list[str]:
    """Split an Top-Level-Kommas (ignoriert Kommas in Klammern, eckigen Klammern, Strings)."""
    parts, depth, cur, in_br, in_str = [], 0, [], False, False
    for ch in s:
        if in_str:
            in_str = ch != "'"
        elif in_br:
            in_br = ch != "]"
        elif ch == "'":
            in_str = True
        elif ch == "[":
            in_br = True
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == sep and depth == 0:
            parts.append("".join(cur).strip())
            cur = []
            continue
        cur.append(ch)
    if "".join(cur).strip():
        parts.append("".join(cur).strip())
    return parts


def _key_cols(s: str) -> list[tuple[str, str]]:
    out = []
    for part in _split_top(s):
        m = re.match(rf"^{_NAME}(?:\s+(ASC|DESC))?$", part, re.I)
        if not m:
            raise ValueError(f"Unbekannte Spaltenangabe: {part!r}")
        out.append((m.group(1).replace("]]", "]"), (m.group(2) or "ASC").upper()))
    return out


def _plain_cols(s: str) -> list[str]:
    return [_unbracket(p) for p in _split_top(s)]


def _statements(sql: str) -> list[str]:
    return [" ".join(st.split()) if not st.lstrip().startswith("CREATE TABLE") else st.strip()
            for st in re.split(r";\s*(?:\n|$)", sql) if st.strip()]


def parse_table_file(path: Path) -> Table:
    sql = path.read_text(encoding="utf-8-sig")
    table: Table | None = None
    for st in _statements(sql):
        if st.startswith("CREATE TABLE"):
            m = _CREATE_RE.match(st)
            if not m:
                raise ValueError(f"{path.name}: CREATE TABLE nicht erkannt")
            table = Table(m.group(1), m.group(2), source=path)
            for item in _split_top(m["body"]):
                item = " ".join(item.split())
                if item.upper().startswith("CONSTRAINT"):
                    km = _KEY_RE.match(item)
                    if not km:
                        raise ValueError(f"{path.name}: Constraint nicht erkannt: {item}")
                    table.keys.append(Key(km.group(1), km["kind"].upper(), _key_cols(km["cols"])))
                    continue
                cm = _COL_RE.match(item)
                if not cm:
                    raise ValueError(f"{path.name}: Spalte nicht erkannt: {item}")
                table.columns.append(Column(
                    name=cm.group(1).replace("]]", "]"),
                    mssql_type=cm["type"],
                    nullable=cm["null"].upper() == "NULL",
                    identity=cm["seed"] is not None,
                    default=cm["default"],
                ))
        elif st.startswith("ALTER TABLE"):
            m = _FK_RE.match(st)
            if not m or table is None:
                raise ValueError(f"{path.name}: ALTER TABLE nicht erkannt: {st}")
            # Gruppen: 1/2 = Tabelle, 3 = FK-Name, 4 = cols (benannt), 5/6 = Referenztabelle
            table.fks.append(ForeignKey(m.group(3), _plain_cols(m["cols"]),
                                        m.group(5), m.group(6), _plain_cols(m["refcols"])))
        elif st.startswith("CREATE") and "INDEX" in st:
            m = _IDX_RE.match(st)
            if not m or table is None:
                raise ValueError(f"{path.name}: Index nicht erkannt: {st}")
            table.indexes.append(Index(m.group(2), bool(m["unique"]), _key_cols(m["cols"]),
                                       _plain_cols(m["incl"]) if m["incl"] else []))
        else:
            raise ValueError(f"{path.name}: Unbekanntes Statement: {st[:80]}")
    if table is None:
        raise ValueError(f"{path.name}: kein CREATE TABLE gefunden")
    return table


def load_tables(tables_dir: Path, include_excluded: bool = False) -> list[Table]:
    tables = [parse_table_file(p) for p in sorted(tables_dir.glob("*.sql"))]
    if not include_excluded:
        tables = [t for t in tables if (t.schema.lower(), t.name.lower()) not in EXCLUDED_TABLES]
    return tables


# --------------------------------------------------------------------------- Defaults


# Schemas, in denen getdate()-Defaults die Echtzeit bekommen (Log-Tabellen: Start/Ende innerhalb
# einer Transaktion sollen unterschiedliche Zeitstempel haben). Sonst: Transaktionszeit.
CLOCK_DEFAULT_SCHEMAS = {"admin"}


def pg_default(col: Column, schema: str = "") -> str:
    """Übersetzt die im Bestand vorkommenden Default-Ausdrücke. Unbekanntes -> Fehler."""
    expr = col.default.strip()
    pgt = col.pg_type
    # ((0)), ((-1)), ((45428123))
    if m := re.fullmatch(r"\(\((-?\d+(?:\.\d+)?)\)\)", expr):
        if pgt == "boolean":
            return "true" if m.group(1) != "0" else "false"
        return m.group(1)
    # ('text')
    if m := re.fullmatch(r"\('((?:[^']|'')*)'\)", expr):
        return f"'{m.group(1)}'"
    if re.fullmatch(r"\(getdate\(\)\)", expr, re.I):
        if pgt == "date":
            return "current_date"
        if schema.lower() in CLOCK_DEFAULT_SCHEMAS:
            return f"clock_timestamp()::{pgt}"
        return "localtimestamp"
    # (CONVERT([datetime],'31.12.9999',(104)))  -> Style 104 = dd.mm.yyyy
    if m := re.fullmatch(r"\(CONVERT\(\[\w+\],'(\d{2})\.(\d{2})\.(\d{4})',\(104\)\)\)", expr, re.I):
        d, mo, y = m.groups()
        datetime(int(y), int(mo), int(d))  # validiert
        if pgt == "date":
            return f"DATE '{y}-{mo}-{d}'"
        return f"TIMESTAMP '{y}-{mo}-{d} 00:00:00'"
    raise ValueError(f"Default nicht übersetzbar: {col.name} DEFAULT {expr}")


# --------------------------------------------------------------------------- Renderer


def render_create(t: Table) -> str:
    lines = []
    for c in t.columns:
        parts = [f"    {quote(c.pg_name)} {c.pg_type}"]
        if c.identity:
            parts.append("GENERATED BY DEFAULT AS IDENTITY")
        if c.default is not None:
            parts.append(f"DEFAULT {pg_default(c, t.schema)}")
        if not c.nullable:
            parts.append("NOT NULL")
        lines.append(" ".join(parts))
    for k in t.keys:
        # Sortierrichtung ist bei PK/UNIQUE-Constraints in PG nicht angebbar (B-Tree ist bidirektional)
        cols = ", ".join(ident(c) for c, _ in k.columns)
        lines.append(f"    CONSTRAINT {ident(k.name)} {k.kind} ({cols})")
    src = t.source.name if t.source else "?"
    return (
        f"-- Quelle: energydwh-main/Tables/{src}\n"
        f"CREATE TABLE {t.pg_qualified}\n(\n" + ",\n".join(lines) + "\n);\n"
    )


def render_fks(t: Table) -> str:
    out = []
    for fk in t.fks:
        out.append(
            f"ALTER TABLE {t.pg_qualified} DROP CONSTRAINT IF EXISTS {ident(fk.name)};\n"
            f"ALTER TABLE {t.pg_qualified}\n"
            f"    ADD CONSTRAINT {ident(fk.name)}\n"
            f"    FOREIGN KEY ({', '.join(ident(c) for c in fk.columns)})\n"
            f"    REFERENCES {qualified(fk.ref_schema, fk.ref_table)} "
            f"({', '.join(ident(c) for c in fk.ref_columns)})\n"
            f"    NOT VALID;\n"
        )
    return "\n".join(out)


def render_indexes(t: Table) -> str:
    out = []
    for ix in t.indexes:
        keycols = [c for c, _ in ix.columns]
        cols = ", ".join(f"{ident(c)}{' DESC' if d == 'DESC' else ''}" for c, d in ix.columns)
        incl = [c for c in ix.include if pg_name(c) not in {pg_name(k) for k in keycols}]
        sql = f"CREATE {'UNIQUE ' if ix.unique else ''}INDEX IF NOT EXISTS {ident(ix.name)}\n    ON {t.pg_qualified} ({cols})"
        if incl:
            sql += f"\n    INCLUDE ({', '.join(ident(c) for c in incl)})"
        out.append(sql + ";\n")
    return "\n".join(out)


def render_identity_reset(t: Table) -> str:
    out = []
    for c in t.columns:
        if c.identity:
            tbl = t.pg_qualified.replace("'", "''")
            col = c.pg_name.replace("'", "''")
            out.append(
                f"SELECT setval(pg_get_serial_sequence('{tbl}', '{col}'),\n"
                f"              COALESCE((SELECT max({quote(c.pg_name)}) FROM {t.pg_qualified}), 0) + 1, false);\n"
            )
    return "".join(out)


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
