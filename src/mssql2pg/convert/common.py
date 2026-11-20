"""Gemeinsame AST-Transformationen T-SQL -> PostgreSQL (auf Basis von sqlglot).

Ablauf: sqlglot parst T-SQL, `normalize()` passt den Baum an unsere Konventionen an
(Bezeichner, Schemas, Typen, Funktionen mit abweichender Semantik), danach erzeugt
sqlglot PostgreSQL-SQL.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime

import sqlglot
from sqlglot import exp

from ..naming import needs_quoting, pg_name
from ..typemap import pg_type

DEFAULT_SCHEMA = "dbo"


class Unsupported(Exception):
    """Konstrukt, das nicht automatisch übersetzt werden kann (-> Status failed)."""


@dataclass
class Ctx:
    getdate: str = "localtimestamp"
    warnings: list[str] = field(default_factory=list)
    # Routinen: T-SQL-Variable (lowercase, ohne @) -> PL/pgSQL-Name
    variables: dict[str, str] = field(default_factory=dict)
    # Ersatz für @@-Systemvariablen (lowercase, ohne @@) -> PG-Ausdruck
    system_vars: dict[str, str] = field(default_factory=dict)
    # Temp-Tabellen (#name) -> PG-Name
    temp_tables: dict[str, str] = field(default_factory=dict)
    # Tabellenvariablen (@name, lowercase) -> Temp-Tabelle
    table_vars: dict[str, str] = field(default_factory=dict)
    # PL/pgSQL-Variable -> PG-Typ (für die Typinferenz)
    var_types: dict[str, str] = field(default_factory=dict)

    def warn(self, msg: str) -> None:
        if msg not in self.warnings:
            self.warnings.append(msg)


def parse_one(sql: str) -> exp.Expr:
    try:
        tree = sqlglot.parse_one(sql, read="tsql", error_level=sqlglot.ErrorLevel.RAISE)
    except sqlglot.errors.ParseError as e:
        raise Unsupported(f"Parserfehler: {str(e).splitlines()[0]}") from e
    if isinstance(tree, exp.Command):
        raise Unsupported(f"Nicht unterstützte Syntax: {sql.strip()[:80]!r}")
    return tree


def to_pg(tree: exp.Expr, pretty: bool = True) -> str:
    try:
        return tree.sql(dialect="postgres", pretty=pretty, unsupported_level=sqlglot.ErrorLevel.RAISE)
    except sqlglot.errors.UnsupportedError as e:
        raise Unsupported(str(e).splitlines()[0]) from e


def pg_ident(name: str) -> exp.Identifier:
    n = pg_name(name)
    return exp.Identifier(this=n, quoted=needs_quoting(n))


# --------------------------------------------------------------------------- Typen


def map_datatype(dt: exp.DataType) -> exp.DataType:
    """T-SQL-Datentyp über typemap auf PG abbilden (identisch zu den Tabellen)."""
    tsql = dt.sql(dialect="tsql")
    if dt.this == exp.DType.USERDEFINED and dt.args.get("kind"):
        tsql = str(dt.args["kind"])
    elif dt.this == exp.DType.UTINYINT:
        tsql = "tinyint"
    try:
        return exp.DataType.build(pg_type(tsql), dialect="postgres")
    except ValueError:
        return dt


# --------------------------------------------------------------------------- Funktionen


def _fn(name: str, *args: exp.Expr) -> exp.Anonymous:
    return exp.Anonymous(this=name, expressions=list(args))


def _date_diff(node: exp.DateDiff, ctx: Ctx) -> exp.Expr:
    """DATEDIFF zählt in T-SQL Grenzübergänge, nicht volle Intervalle."""
    unit = (node.text("unit") or "day").lower()
    end, start = node.this, node.expression

    def ext(part: str, e: exp.Expr) -> exp.Expr:
        return exp.Extract(this=exp.var(part), expression=exp.cast(e.copy(), "timestamp"))

    if unit in ("year", "yy", "yyyy"):
        r = exp.Sub(this=ext("year", end), expression=ext("year", start))
    elif unit in ("month", "mm", "m"):
        r = exp.Add(
            this=exp.Mul(this=exp.Paren(this=exp.Sub(this=ext("year", end), expression=ext("year", start))),
                         expression=exp.Literal.number(12)),
            expression=exp.Sub(this=ext("month", end), expression=ext("month", start)),
        )
    elif unit in ("day", "dd", "d", "dayofyear", "dy", "y"):
        r = exp.Sub(this=exp.cast(end.copy(), "date"), expression=exp.cast(start.copy(), "date"))
    elif unit in ("hour", "hh", "minute", "mi", "n", "second", "ss", "s"):
        part, secs = {"h": ("hour", 3600), "m": ("minute", 60), "n": ("minute", 60), "s": ("second", 1)}[unit[0]]

        def tr(e: exp.Expr) -> exp.Expr:
            return _fn("date_trunc", exp.Literal.string(part), exp.cast(e.copy(), "timestamp"))

        r = exp.Div(
            this=exp.Extract(this=exp.var("epoch"), expression=exp.Paren(this=exp.Sub(this=tr(end), expression=tr(start)))),
            expression=exp.Literal.number(secs),
        )
    else:
        raise Unsupported(f"DATEDIFF mit Einheit {unit!r}")
    return exp.cast(exp.Paren(this=r), "integer")


def _is_stringish(e: exp.Expr) -> bool:
    if isinstance(e, exp.Literal) and e.is_string:
        return True
    if isinstance(e, (exp.National, exp.DPipe, exp.Concat)):
        return True
    if isinstance(e, exp.Cast) and e.to.is_type(*exp.DataType.TEXT_TYPES):
        return True
    if isinstance(e, exp.Add):
        return _is_stringish(e.this) or _is_stringish(e.expression)
    if isinstance(e, exp.Paren):
        return _is_stringish(e.this)
    if isinstance(e, (exp.Upper, exp.Lower, exp.Trim, exp.Substring, exp.Left, exp.Right)):
        return True
    if isinstance(e, exp.Anonymous) and e.name.lower() in ("ltrim", "rtrim", "replace", "stuff", "replicate", "format"):
        return True
    return False


# CONVERT-Styles für Datum/Zeit -> PG-Formatmaske
DATE_STYLES = {
    1: "MM/DD/YY", 101: "MM/DD/YYYY", 2: "YY.MM.DD", 102: "YYYY.MM.DD",
    3: "DD/MM/YY", 103: "DD/MM/YYYY", 4: "DD.MM.YY", 104: "DD.MM.YYYY",
    5: "DD-MM-YY", 105: "DD-MM-YYYY", 10: "MM-DD-YY", 110: "MM-DD-YYYY",
    11: "YY/MM/DD", 111: "YYYY/MM/DD", 12: "YYMMDD", 112: "YYYYMMDD",
    8: "HH24:MI:SS", 108: "HH24:MI:SS", 23: "YYYY-MM-DD",
    20: "YYYY-MM-DD HH24:MI:SS", 120: "YYYY-MM-DD HH24:MI:SS",
    21: "YYYY-MM-DD HH24:MI:SS.MS", 121: "YYYY-MM-DD HH24:MI:SS.MS",
    126: 'YYYY-MM-DD"T"HH24:MI:SS.MS', 127: 'YYYY-MM-DD"T"HH24:MI:SS.MS',
}


PY_STYLES = {103: "%d/%m/%Y", 104: "%d.%m.%Y", 105: "%d-%m-%Y", 112: "%Y%m%d", 23: "%Y-%m-%d",
             101: "%m/%d/%Y", 120: "%Y-%m-%d %H:%M:%S", 20: "%Y-%m-%d %H:%M:%S"}


def _convert(node: exp.Convert, ctx: Ctx) -> exp.Expr:
    target = node.this if isinstance(node.this, exp.DataType) else exp.DataType.build(node.this.sql())
    target = map_datatype(target)
    value = node.expression
    style = node.args.get("style")
    while isinstance(style, exp.Paren):
        style = style.this
    if style is None or not isinstance(style, exp.Literal) or style.is_string:
        return exp.Cast(this=value, to=target)
    fmt = DATE_STYLES.get(int(style.this))
    if fmt and isinstance(value, exp.Literal) and value.is_string \
            and target.is_type(*exp.DataType.TEMPORAL_TYPES) and int(style.this) in PY_STYLES:
        # Konstante: direkt als ISO-Literal
        pyfmt = PY_STYLES[int(style.this)]
        try:
            d = datetime.strptime(value.this, pyfmt)
        except ValueError:
            d = datetime.strptime(value.this, pyfmt.split(" ")[0])
        if target.is_type(exp.DType.DATE):
            return exp.cast(exp.Literal.string(d.strftime("%Y-%m-%d")), "date")
        return exp.Cast(this=exp.Literal.string(d.strftime("%Y-%m-%d %H:%M:%S")), to=target)
    if fmt is None:
        if int(style.this) not in (0, 100):
            ctx.warn(f"CONVERT-Style {style.this} ignoriert")
        return exp.Cast(this=value, to=target)
    mask = exp.Literal.string(fmt)
    if target.is_type(*exp.DataType.TEXT_TYPES):
        return exp.Cast(this=_fn("to_char", value, mask), to=target)
    if target.is_type(exp.DType.DATE):
        return _fn("to_date", value, mask)
    if target.is_type(*exp.DataType.TEMPORAL_TYPES):
        return exp.Cast(this=_fn("to_timestamp", value, mask), to=target)
    return exp.Cast(this=value, to=target)


def _anonymous(node: exp.Anonymous, ctx: Ctx) -> exp.Expr:
    name = node.name.lower()
    a = node.expressions
    if name == "isnumeric" and len(a) == 1:
        return exp.If(
            this=exp.RegexpLike(this=exp.cast(a[0], "text"), expression=exp.Literal.string(r"^\s*[-+]?(\d+\.?\d*|\.\d+)\s*$")),
            true=exp.Literal.number(1), false=exp.Literal.number(0))
    if name == "datefromparts" and len(a) == 3:
        return _fn("make_date", *a)
    if name in ("getutcdate", "sysutcdatetime"):
        return exp.cast(exp.AtTimeZone(this=exp.CurrentTimestamp(), zone=exp.Literal.string("UTC")), "timestamp")
    if name == "patindex" and len(a) == 2 and isinstance(a[0], exp.Literal) and a[0].is_string:
        return _fn("regexp_instr", a[1], exp.Literal.string(like_to_regex(a[0].this)))
    if name in ("checksum", "binary_checksum") and a:
        # Änderungserkennung: Hash über die Zeile (NULL-sicher); Werte nicht kompatibel zu MSSQL
        return _fn("hashtext", exp.cast(exp.Tuple(expressions=list(a)) if len(a) > 1 else
                                        _fn("row", a[0]), "text"))
    if name == "scope_identity":
        return _fn("lastval")
    if name == "newid":
        return _fn("gen_random_uuid")
    if name in ("error_message",):
        return exp.column("sqlerrm")
    if name in ("error_number", "error_state", "error_severity"):
        return exp.column("sqlstate")
    if name in ("error_procedure", "error_line"):
        return exp.Null()
    return node


def like_to_regex(pattern: str) -> str:
    """T-SQL LIKE-Muster (%, _, [..]) -> POSIX-Regex; ohne führendes/abschließendes % verankert."""
    out = []
    i = 0
    while i < len(pattern):
        ch = pattern[i]
        if ch == "%":
            out.append(".*")
        elif ch == "_":
            out.append(".")
        elif ch == "[":
            j = pattern.find("]", i + 1)
            if j == -1:
                out.append(r"\[")
            else:
                body = pattern[i + 1:j]
                out.append("[" + ("^" + body[1:] if body.startswith("^") else body) + "]")
                i = j
        else:
            out.append("\\" + ch if ch in ".^$*+?(){}|\\" else ch)
        i += 1
    rx = "".join(out)
    rx = rx[2:] if rx.startswith(".*") else "^" + rx
    rx = rx[:-2] if rx.endswith(".*") else rx + "$"
    return rx


def _transform(node: exp.Expr, ctx: Ctx, cte_names: set[str]) -> exp.Expr:
    # Variablen @x / Systemvariablen @@x
    if isinstance(node, exp.Parameter):
        if isinstance(node.parent, exp.Parameter):
            return node
        inner = node.this
        if isinstance(inner, exp.Parameter):
            sys_name = inner.name.lower()
            if sys_name in ctx.system_vars:
                return sqlglot.parse_one(ctx.system_vars[sys_name], read="postgres")
            raise Unsupported(f"Systemvariable @@{sys_name}")
        var = node.name.lower()
        if isinstance(node.parent, exp.Table) and var in ctx.table_vars:
            return exp.Identifier(this=ctx.table_vars[var], quoted=False)
        if var in ctx.variables:
            return exp.column(ctx.variables[var])
        raise Unsupported(f"Unbekannte Variable @{var}")

    if isinstance(node, exp.Identifier):
        raw = node.this
        if raw.startswith("#") or node.args.get("temporary"):
            key = raw.lstrip("#").lower()
            new = ctx.temp_tables.setdefault(key, f"tmp_{pg_name(key)}")
            return exp.Identifier(this=new, quoted=False)
        if node.quoted or not raw.startswith("@"):
            return pg_ident(raw)
        return node

    if isinstance(node, exp.Table):
        if node.args.get("catalog"):
            ctx.warn(f"Datenbankname entfernt: {node.sql(dialect='tsql')}")
            node.set("catalog", None)
        name = node.name
        if not node.args.get("db") and name and not name.startswith("#") \
                and name.lower() not in cte_names and isinstance(node.this, exp.Identifier) \
                and name not in ctx.temp_tables.values():
            node.set("db", exp.to_identifier(DEFAULT_SCHEMA))
        hints = node.args.get("hints")
        if hints:
            node.set("hints", None)
        return node

    if isinstance(node, exp.DataType):
        return map_datatype(node)

    if isinstance(node, exp.OnProperty):        # Filegroup: ON [PRIMARY]
        node.pop()
        return node

    if isinstance(node, exp.Create) and "INDEX" in str(node.kind):
        node.set("kind", "INDEX")
        return node

    if isinstance(node, (exp.CurrentTimestamp, exp.CurrentDatetime)) or (
        isinstance(node, exp.Anonymous) and node.name.lower() in ("getdate", "sysdatetime")
    ):
        return sqlglot.parse_one(ctx.getdate, read="postgres")

    if isinstance(node, exp.DateDiff):
        return _date_diff(node, ctx)

    if isinstance(node, exp.National):
        return exp.Literal.string(node.this)

    if isinstance(node, exp.Add) and (_is_stringish(node.this) or _is_stringish(node.expression)):
        return exp.DPipe(this=node.this, expression=node.expression, safe=False)

    if isinstance(node, exp.ObjectId):
        arg = node.this
        if isinstance(arg, exp.Literal) and arg.is_string:
            parts = [x for x in arg.this.split(".") if x]
            if parts and parts[-1].startswith("#"):
                key = parts[-1].lstrip("#").lower()
                return _fn("to_regclass", exp.Literal.string(
                    "pg_temp." + ctx.temp_tables.setdefault(key, f"tmp_{pg_name(key)}")))
            return _fn("to_regclass", exp.Literal.string(".".join(pg_name(x) for x in parts[-2:])))
        return _fn("to_regclass", exp.cast(arg, "text"))

    if isinstance(node, exp.Convert):
        return _convert(node, ctx)

    if isinstance(node, exp.Stuff):
        return exp.Overlay(this=node.this, expression=node.expression,
                           from_=node.args["start"], for_=node.args["length"])

    if isinstance(node, exp.DateFromParts):
        return _fn("make_date", node.args["year"], node.args["month"], node.args["day"])

    if isinstance(node, exp.TryCast):
        # PG16+: pg_input_is_valid prüft ohne Exception -> exakt TRY_CAST-Semantik
        txt = exp.cast(node.this.copy(), "text")
        typ = exp.Literal.string(node.to.sql(dialect="postgres"))
        return exp.Case(ifs=[exp.If(this=_fn("pg_input_is_valid", txt, typ),
                                    true=exp.Cast(this=node.this, to=node.to))])

    if isinstance(node, exp.Anonymous):
        return _anonymous(node, ctx)

    return node


def normalize(tree: exp.Expr, ctx: Ctx) -> exp.Expr:
    """Post-Order: Kinder werden vor ihren Eltern umgeschrieben."""
    cte_names = {c.alias_or_name.lower() for c in tree.find_all(exp.CTE)}
    # T-SQL kennt kein RECURSIVE – CTE, die sich selbst referenziert, braucht es in PG
    for w in tree.find_all(exp.With):
        for cte in w.expressions:
            name = cte.alias_or_name.lower()
            if any(t.name.lower() == name and not t.args.get("db") for t in cte.this.find_all(exp.Table)):
                w.set("recursive", True)
    nodes = list(tree.walk())
    for n in reversed(nodes):
        new = _transform(n, ctx, cte_names)
        if new is not n:
            if n is tree:
                tree = new
            else:
                n.replace(new)
    return tree


def translate_expr(sql: str, ctx: Ctx) -> str:
    """Einzelner T-SQL-Ausdruck -> PG-Ausdruck."""
    try:
        e = sqlglot.parse_one(f"SELECT {sql}", read="tsql")
    except sqlglot.errors.ParseError as ex:
        raise Unsupported(f"Ausdruck nicht parsebar: {sql!r}") from ex
    e = normalize(e, ctx)
    return to_pg(e.expressions[0], pretty=False)
