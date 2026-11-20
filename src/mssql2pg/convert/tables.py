"""Tabellen: T-SQL-Skript (CREATE TABLE, ALTER TABLE ... FOREIGN KEY, CREATE INDEX) -> Modell -> PG-DDL.

Das Modell (Table/Column) hält bereits die fertigen PG-Namen und -Typen, damit es ohne
globalen Zustand (Umbenennungen) an Kopier-Worker-Prozesse übergeben werden kann.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field

import sqlglot
from sqlglot import exp

from ..model import PgObject, SourceObject
from ..naming import pg_name, quote
from ..typemap import pg_type
from .common import Ctx, Unsupported, normalize, to_pg

# --------------------------------------------------------------------------- Modell


@dataclass
class Column:
    name: str                 # Original MSSQL
    pg_name: str
    mssql_type: str
    pg_type: str
    nullable: bool
    identity: bool = False
    default: str | None = None     # bereits übersetzter PG-Ausdruck


@dataclass
class Key:
    name: str
    kind: str                       # 'PRIMARY KEY' | 'UNIQUE'
    columns: list[str]              # PG-Spaltennamen


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
    columns: list[tuple[str, bool]]  # (PG-Spalte, desc)
    include: list[str]
    where: str | None = None


@dataclass
class Table:
    schema: str               # Original MSSQL
    name: str
    pg_schema: str
    pg_table: str
    columns: list[Column] = field(default_factory=list)
    keys: list[Key] = field(default_factory=list)
    fks: list[ForeignKey] = field(default_factory=list)
    indexes: list[Index] = field(default_factory=list)

    @property
    def key(self) -> str:
        return f"{self.pg_schema}.{self.pg_table}"

    @property
    def mssql_qualified(self) -> str:
        return f"[{self.schema.replace(']', ']]')}].[{self.name.replace(']', ']]')}]"

    @property
    def pg_qualified(self) -> str:
        return f"{quote(self.pg_schema)}.{quote(self.pg_table)}"

    @property
    def primary_key(self) -> Key | None:
        return next((k for k in self.keys if k.kind == "PRIMARY KEY"), None)

    def column(self, pg: str) -> Column | None:
        return next((c for c in self.columns if c.pg_name == pg.lower()), None)


# --------------------------------------------------------------------------- Defaults

_NUM_RE = re.compile(r"^\(*(-?\d+(?:\.\d+)?)\)*$")


def _strip_parens(e: exp.Expr) -> exp.Expr:
    while isinstance(e, exp.Paren):
        e = e.this
    return e


def pg_default(expr: exp.Expr, pgtype: str, ctx: Ctx) -> str:
    e = _strip_parens(expr)
    if pgtype == "boolean" and isinstance(e, exp.Literal) and not e.is_string:
        return "true" if e.this not in ("0", 0) else "false"
    if isinstance(e, exp.Neg) and isinstance(_strip_parens(e.this), exp.Literal):
        return "-" + str(_strip_parens(e.this).this)
    e = normalize(e.copy(), ctx)
    sql = to_pg(e, pretty=False)
    if pgtype == "date" and sql.lower() == ctx.getdate.lower():
        return "current_date"
    return sql


# --------------------------------------------------------------------------- Parser


def _col_names(items) -> list[str]:
    out = []
    for i in items:
        if isinstance(i, exp.Ordered):
            i = i.this
        out.append(pg_name(i.name))
    return out


def _ordered(items) -> list[tuple[str, bool]]:
    out = []
    for i in items:
        desc = bool(i.args.get("desc")) if isinstance(i, exp.Ordered) else False
        col = i.this if isinstance(i, exp.Ordered) else i
        out.append((pg_name(col.name), desc))
    return out


def _parse_create(tree: exp.Create, ctx: Ctx, obj: PgObject) -> Table:
    schema_node = tree.this
    tbl = schema_node.this
    t = Table(tbl.db or "dbo", tbl.name, pg_name(tbl.db or "dbo"), pg_name(tbl.name))
    for item in schema_node.expressions:
        if isinstance(item, exp.ColumnDef):
            t.columns.append(_parse_column(item, ctx, obj))
        elif isinstance(item, exp.Constraint):
            name = item.name
            for c in item.expressions:
                if isinstance(c, exp.PrimaryKeyColumnConstraint):
                    continue
                if isinstance(c, (exp.ClusteredColumnConstraint, exp.NonClusteredColumnConstraint)):
                    kind = "UNIQUE" if any(isinstance(x, exp.UniqueColumnConstraint) for x in item.expressions) \
                        else "PRIMARY KEY"
                    t.keys.append(Key(pg_name(name), kind, _col_names(c.this)))
                elif isinstance(c, exp.UniqueColumnConstraint):
                    inner = c.this
                    cols = inner.this if isinstance(inner, (exp.ClusteredColumnConstraint,
                                                           exp.NonClusteredColumnConstraint)) else inner.expressions
                    t.keys.append(Key(pg_name(name), "UNIQUE", _col_names(cols)))
                elif isinstance(c, exp.PrimaryKey):
                    t.keys.append(Key(pg_name(name), "PRIMARY KEY", _col_names(c.expressions)))
                elif isinstance(c, exp.ForeignKey):
                    t.fks.append(_fk(name, c))
                elif isinstance(c, exp.CheckColumnConstraint):
                    obj.warn(f"CHECK-Constraint {name} nicht übernommen")
                else:
                    raise Unsupported(f"Tabellen-Constraint {name}: {c.sql(dialect='tsql')}")
        elif isinstance(item, exp.PrimaryKey):
            t.keys.append(Key(f"pk_{t.pg_table}"[:63], "PRIMARY KEY", _col_names(item.expressions)))
        else:
            raise Unsupported(f"Tabellenelement nicht unterstützt: {item.sql(dialect='tsql')[:80]}")
    return t


def _parse_column(cd: exp.ColumnDef, ctx: Ctx, obj: PgObject) -> Column:
    dt = cd.args.get("kind")
    if dt is None:
        raise Unsupported(f"Spalte {cd.name}: berechnete Spalten werden nicht unterstützt")
    mssql_type = str(dt.args["kind"]) if dt.this == exp.DType.USERDEFINED else dt.sql(dialect="tsql")
    if dt.this == exp.DType.UTINYINT:
        mssql_type = "tinyint"
    try:
        pgt = pg_type(mssql_type)
    except ValueError as e:
        raise Unsupported(f"Spalte {cd.name}: {e}") from e
    col = Column(cd.name, pg_name(cd.name), mssql_type, pgt, nullable=True)
    for cc in cd.constraints:
        k = cc.kind
        if isinstance(k, exp.NotNullColumnConstraint):
            col.nullable = bool(k.args.get("allow_null"))
        elif isinstance(k, exp.GeneratedAsIdentityColumnConstraint):
            col.identity = True
        elif isinstance(k, exp.DefaultColumnConstraint):
            col.default = pg_default(k.this, pgt, ctx)
        elif isinstance(k, exp.CollateColumnConstraint):
            pass
        elif isinstance(k, exp.PrimaryKeyColumnConstraint):
            obj.warn(f"Inline-PK auf {cd.name}")
        elif isinstance(k, exp.ComputedColumnConstraint):
            raise Unsupported(f"Spalte {cd.name}: berechnete Spalte")
        else:
            raise Unsupported(f"Spalte {cd.name}: Constraint {cc.sql(dialect='tsql')}")
    return col


def _fk(name: str, fk: exp.ForeignKey) -> ForeignKey:
    ref = fk.args["reference"].this
    rt = ref.this
    return ForeignKey(pg_name(name), _col_names(fk.expressions), pg_name(rt.db or "dbo"),
                      pg_name(rt.name), _col_names(ref.expressions))


def parse_table(src: SourceObject, ctx: Ctx, obj: PgObject) -> Table:
    table: Table | None = None
    for batch in src.batches:
        for stmt in sqlglot.parse(batch, read="tsql", error_level=sqlglot.ErrorLevel.RAISE):
            if stmt is None:
                continue
            if isinstance(stmt, exp.Create) and stmt.kind == "TABLE":
                if table is not None:
                    raise Unsupported("Mehrere CREATE TABLE in einer Datei")
                table = _parse_create(stmt, ctx, obj)
            elif isinstance(stmt, exp.Alter) and table is not None:
                for action in stmt.args.get("actions") or []:
                    if isinstance(action, exp.AddConstraint):
                        for con in action.expressions:
                            for c in con.expressions:
                                if isinstance(c, exp.ForeignKey):
                                    table.fks.append(_fk(con.name, c))
                                elif isinstance(c, exp.CheckColumnConstraint):
                                    obj.warn(f"CHECK-Constraint {con.name} nicht übernommen")
                                else:
                                    raise Unsupported(f"ALTER TABLE: {c.sql(dialect='tsql')[:80]}")
                    else:
                        raise Unsupported(f"ALTER TABLE: {action.sql(dialect='tsql')[:80]}")
            elif isinstance(stmt, exp.Create) and "INDEX" in str(stmt.kind) and table is not None:
                idx = stmt.this
                params = idx.args["params"]
                where = params.args.get("where")
                table.indexes.append(Index(
                    pg_name(idx.name),
                    bool(stmt.args.get("unique")),
                    _ordered(params.args.get("columns") or []),
                    _col_names(params.args.get("include") or []),
                    to_pg(normalize(where.this.copy(), ctx), pretty=False) if where else None,
                ))
            elif isinstance(stmt, exp.Command) and stmt.this.upper() == "SET":
                continue
            else:
                raise Unsupported(f"Unbekanntes Statement: {stmt.sql(dialect='tsql')[:80]}")
    if table is None:
        raise Unsupported("kein CREATE TABLE gefunden")
    return table


# --------------------------------------------------------------------------- Renderer


def render_create(t: Table) -> str:
    lines = []
    for c in t.columns:
        parts = [f"    {quote(c.pg_name)} {c.pg_type}"]
        if c.identity:
            parts.append("GENERATED BY DEFAULT AS IDENTITY")
        if c.default is not None:
            parts.append(f"DEFAULT {c.default}")
        if not c.nullable:
            parts.append("NOT NULL")
        lines.append(" ".join(parts))
    for k in t.keys:
        cols = ", ".join(quote(c) for c in k.columns)
        lines.append(f"    CONSTRAINT {quote(k.name)} {k.kind} ({cols})")
    return f"CREATE TABLE {t.pg_qualified}\n(\n" + ",\n".join(lines) + "\n);\n"


def render_post(t: Table) -> str:
    """Indizes + FKs (NOT VALID) – laufen nach der Datenkopie."""
    out = []
    for ix in t.indexes:
        keycols = {c for c, _ in ix.columns}
        cols = ", ".join(f"{quote(c)}{' DESC' if d else ''}" for c, d in ix.columns)
        sql = f"CREATE {'UNIQUE ' if ix.unique else ''}INDEX IF NOT EXISTS {quote(ix.name)}\n    ON {t.pg_qualified} ({cols})"
        incl = [c for c in ix.include if c not in keycols]
        if incl:
            sql += f"\n    INCLUDE ({', '.join(quote(c) for c in incl)})"
        if ix.where:
            sql += f"\n    WHERE {ix.where}"
        out.append(sql + ";\n")
    for fk in t.fks:
        out.append(
            f"ALTER TABLE {t.pg_qualified} DROP CONSTRAINT IF EXISTS {quote(fk.name)};\n"
            f"ALTER TABLE {t.pg_qualified}\n"
            f"    ADD CONSTRAINT {quote(fk.name)}\n"
            f"    FOREIGN KEY ({', '.join(quote(c) for c in fk.columns)})\n"
            f"    REFERENCES {quote(fk.ref_schema)}.{quote(fk.ref_table)} ({', '.join(quote(c) for c in fk.ref_columns)})\n"
            f"    NOT VALID;\n"
        )
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


def convert_table(src: SourceObject, getdate: str) -> tuple[PgObject, Table | None]:
    obj = PgObject(src.key, "table", pg_name(src.schema), pg_name(src.name), source=str(src.path))
    ctx = Ctx(getdate=getdate)
    try:
        t = parse_table(src, ctx, obj)
    except (Unsupported, ValueError) as e:
        obj.fail(str(e))
        return obj, None
    except Exception as e:  # noqa: BLE001 – sqlglot-Parserfehler u.ä.
        obj.fail(f"Parserfehler: {str(e).splitlines()[0]}")
        return obj, None
    for w in ctx.warnings:
        obj.warn(w)
    obj.sql = render_create(t)
    obj.post_sql = render_post(t)
    return obj, t
