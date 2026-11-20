"""Typinferenz + implizite T-SQL-Konvertierungen explizit machen.

T-SQL konvertiert bei Typkonflikten implizit nach Datentyp-Rangfolge (z.B. varchar -> int beim
Vergleich `int_spalte = varchar_spalte`). PostgreSQL verlangt explizite Casts. Daher:

1. sqlglot `qualify` (Spalten qualifizieren, `*` expandieren) + `annotate_types` mit dem
   Schema aller Tabellen (und bereits konvertierter Views).
2. Konflikte nach T-SQL-Rangfolge auflösen: Casts einfügen, `bit = 1` -> `= TRUE`,
   `datetime + n` -> `+ n * INTERVAL '1 day'`, `+` auf Strings -> `||`, CONVERT-Style auf Strings entfernen.

Die Ausgabe ist danach qualifiziert (`alias.spalte`) und ohne `*` – semantisch identisch,
PostgreSQL expandiert `*` in Views ohnehin beim Anlegen.
"""

from __future__ import annotations

from sqlglot import exp
from sqlglot.optimizer.annotate_types import annotate_types
from sqlglot.optimizer.qualify import qualify
from sqlglot.schema import MappingSchema

from .common import Ctx

T = exp.DType
_INT = {T.TINYINT, T.SMALLINT, T.INT, T.BIGINT, T.UTINYINT}
_DEC = {T.DECIMAL, T.MONEY, T.SMALLMONEY}
_FLOAT = {T.FLOAT, T.DOUBLE}
_TEXT = set(exp.DataType.TEXT_TYPES) | {T.CHAR, T.NCHAR, T.VARCHAR, T.NVARCHAR, T.TEXT}
_TS = {T.TIMESTAMP, T.TIMESTAMPTZ, T.DATETIME, T.DATETIME2, T.SMALLDATETIME, T.TIMESTAMPLTZ}
_DATE = {T.DATE}
_TIME = {T.TIME}


def category(dt: exp.DataType | None) -> int | None:
    """T-SQL-Rangfolge (höher gewinnt): temporal 6 > float 5 > decimal 4 > int 3 > bool 2 > text 1."""
    if dt is None:
        return None
    t = dt.this
    if t in _TS or t in _DATE or t in _TIME:
        return 6
    if t in _FLOAT:
        return 5
    if t in _DEC:
        return 4
    if t in _INT:
        return 3
    if t == T.BOOLEAN:
        return 2
    if t in _TEXT:
        return 1
    return None


class TypeSchema:
    """Spaltentypen aller bekannten Tabellen/Views (PG-Namen)."""

    def __init__(self) -> None:
        self.mapping: dict[str, dict[str, dict[str, str]]] = {}
        self.identity: dict[tuple[str, str], set[str]] = {}
        self._schema: MappingSchema | None = None

    def add(self, schema: str, name: str, columns: dict[str, str], identity: set[str] | None = None) -> None:
        if not columns:
            return
        self.mapping.setdefault(schema, {})[name] = columns
        if identity:
            self.identity[(schema, name)] = set(identity)
        self._schema = None

    @property
    def schema(self) -> MappingSchema:
        if self._schema is None:
            self._schema = MappingSchema(self.mapping, dialect="postgres", normalize=False)
        return self._schema


def _type(node: exp.Expr, ctx: Ctx) -> exp.DataType | None:
    if isinstance(node, exp.Paren):
        return _type(node.this, ctx)
    if isinstance(node, exp.Column) and not node.table and node.name in ctx.var_types:
        return exp.DataType.build(ctx.var_types[node.name], dialect="postgres")
    t = node.type
    if t is not None and t.this not in (T.UNKNOWN, T.NULL):
        return t
    # Fallbacks, wenn annotate_types den Typ nicht kennt (z.B. wegen PL/pgSQL-Variablen)
    if isinstance(node, exp.Literal):
        if node.is_string:
            return exp.DataType.build("varchar")
        return exp.DataType.build("numeric" if "." in str(node.this) else "int")
    if isinstance(node, exp.Cast):
        return node.to
    if isinstance(node, (exp.DPipe, exp.Concat, exp.Upper, exp.Lower, exp.Trim, exp.Substring, exp.Left,
                         exp.Right, exp.Overlay)):
        return exp.DataType.build("text")
    if isinstance(node, exp.Anonymous) and node.name.lower() in ("ltrim", "rtrim", "replace", "concat_ws", "repeat"):
        return exp.DataType.build("text")
    if isinstance(node, exp.Coalesce):
        return next((x for x in (_type(a, ctx) for a in [node.this, *node.expressions]) if x is not None), None)
    if isinstance(node, exp.Case):
        branches = [i.args["true"] for i in node.args.get("ifs") or []] + \
            ([node.args["default"]] if node.args.get("default") is not None else [])
        return next((x for x in (_type(b, ctx) for b in branches if not _is_str_literal(b)) if x is not None), None)
    return None


def _is_str_literal(n: exp.Expr) -> bool:
    while isinstance(n, exp.Paren):
        n = n.this
    return isinstance(n, exp.Literal) and n.is_string


def _is_num_literal(n: exp.Expr) -> exp.Literal | None:
    while isinstance(n, exp.Paren):
        n = n.this
    if isinstance(n, exp.Neg):
        return None
    return n if isinstance(n, exp.Literal) and not n.is_string else None


def _is_null(n: exp.Expr) -> bool:
    while isinstance(n, exp.Paren):
        n = n.this
    return isinstance(n, exp.Null)


def _cast(node: exp.Expr, to: exp.DataType) -> exp.Expr:
    c = exp.Cast(this=node.copy(), to=to.copy())
    c.type = to.copy()
    return c


def _empty_string_value(target: exp.DataType) -> exp.Expr | None:
    """T-SQL: '' -> 0 für Ganz-/Gleitkommazahlen, 1900-01-01 für Datum/Zeit."""
    c = category(target)
    if c in (3, 5):
        return exp.Literal.number(0)
    if c == 6:
        return exp.cast(exp.Literal.string("1900-01-01"), target.copy())
    return None


def _is_empty_string(n: exp.Expr) -> bool:
    return _is_str_literal(n) and (n.this if isinstance(n, exp.Literal) else n.unnest().this) == ""


def _target_type(types: list[exp.DataType]) -> exp.DataType:
    """Höchster Typ nach Rangfolge; bei gleicher Kategorie der erste."""
    return max(types, key=lambda t: category(t) or 0)


def _coerce_pair(a: exp.Expr, b: exp.Expr, ctx: Ctx) -> tuple[exp.Expr, exp.Expr]:
    """Vergleichsoperanden: den Operanden niedrigerer Rangfolge auf den Typ des anderen casten."""
    ta, tb = _type(a, ctx), _type(b, ctx)
    ca, cb = category(ta), category(tb)
    if ca is None or cb is None or ca == cb:
        return a, b
    # bit/boolean gegen Zahl: Literal 0/1 -> FALSE/TRUE, sonst boolean -> int
    for x, y, cx, cy, swap in ((a, b, ca, cb, False), (b, a, cb, ca, True)):
        if cx == 2 and cy in (3, 4, 5):
            lit = _is_num_literal(y)
            new_y = exp.Boolean(this=lit.this not in ("0", 0)) if lit is not None else None
            new_x = x if new_y is not None else _cast(x, exp.DataType.build("int"))
            if new_y is None:
                new_y = y
            return (new_y, new_x) if swap else (new_x, new_y)
    # '' wird von T-SQL zu 0 bzw. 1900-01-01, PostgreSQL lehnt es ab
    if ca == 1 and _is_empty_string(a) and (v := _empty_string_value(tb)) is not None:
        return v, b
    if cb == 1 and _is_empty_string(b) and (v := _empty_string_value(ta)) is not None:
        return a, v
    # Text-Literale löst PostgreSQL selbst auf (Typ unknown)
    if (ca == 1 and _is_str_literal(a)) or (cb == 1 and _is_str_literal(b)):
        return a, b
    if ca == 1 and cb > 1:
        return _cast(a, tb), b
    if cb == 1 and ca > 1:
        return a, _cast(b, ta)
    return a, b


def _coerce_list(items: list[exp.Expr], ctx: Ctx, target: exp.DataType | None = None) -> list[exp.Expr]:
    """CASE/COALESCE/UNION-Spalten: Text-Ausdrücke auf den höchsten Typ casten; bool<->Zahl angleichen."""
    typed = [(i, _type(i, ctx)) for i in items]
    known = [t for i, t in typed if t is not None and not _is_str_literal(i) and not _is_null(i)]
    if not known:
        return items
    target = target or _target_type(known)
    ct = category(target)
    out = []
    for i, t in typed:
        c = category(t)
        if t is None or c is None or c == ct or _is_null(i):
            out.append(i)
        elif ct == 1:
            # ISNULL(varchar, 0): Ergebnis ist Text -> Zahl als Text
            out.append(_cast(i, target) if not _is_str_literal(i) else i)
        elif _is_str_literal(i):
            v = _empty_string_value(target) if _is_empty_string(i) else None
            out.append(v if v is not None else i)
        elif c == 2 and ct in (3, 4, 5):
            out.append(_cast(i, exp.DataType.build("int")))
        elif c in (1, 3, 4, 5) and ct in (2, 3, 4, 5, 6):
            lit = _is_num_literal(i)
            if ct == 2 and lit is not None:
                out.append(exp.Boolean(this=lit.this not in ("0", 0)))
            else:
                out.append(_cast(i, target))
        else:
            out.append(i)
    return out


_CMP = (exp.EQ, exp.NEQ, exp.GT, exp.GTE, exp.LT, exp.LTE, exp.NullSafeEQ, exp.NullSafeNEQ)


def _fix(node: exp.Expr, ctx: Ctx) -> exp.Expr:
    if isinstance(node, _CMP):
        a, b = _coerce_pair(node.this, node.expression, ctx)
        if a is not node.this:
            node.set("this", a)
        if b is not node.expression:
            node.set("expression", b)
        return node

    if isinstance(node, exp.In) and node.expressions:
        t = _type(node.this, ctx)
        c = category(t)
        if c is not None:
            new = []
            for e in node.expressions:
                _, b = _coerce_pair(node.this, e, ctx)
                new.append(b)
            node.set("expressions", new)
            types = [category(_type(e, ctx)) for e in node.expressions if not _is_str_literal(e)]
            if c == 1 and types and all(x is not None and x > 1 for x in types):
                node.set("this", _cast(node.this, _type(node.expressions[0], ctx)))
        return node

    if isinstance(node, exp.Between):
        a, lo = _coerce_pair(node.this, node.args["low"], ctx)
        a, hi = _coerce_pair(a, node.args["high"], ctx)
        node.set("this", a)
        node.set("low", lo)
        node.set("high", hi)
        return node

    if isinstance(node, exp.Coalesce):
        items = [node.this, *node.expressions]
        # ISNULL: Ergebnistyp = Typ des ersten Arguments; COALESCE: Rangfolge
        first = _type(node.this, ctx) if node.args.get("is_null") else None
        items = _coerce_list(items, ctx, target=first)
        node.set("this", items[0])
        node.set("expressions", items[1:])
        return node

    if isinstance(node, exp.Case):
        branches = [i.args["true"] for i in node.args.get("ifs") or []]
        default = node.args.get("default")
        items = _coerce_list(branches + ([default] if default is not None else []), ctx)
        for i, new in zip(node.args.get("ifs") or [], items):
            i.set("true", new)
        if default is not None:
            node.set("default", items[-1])
        return node

    if isinstance(node, (exp.Add, exp.Sub)):
        ta, tb = _type(node.this, ctx), _type(node.expression, ctx)
        ca, cb = category(ta), category(tb)
        # datetime + datetime: T-SQL addiert den zweiten Wert als Tage seit 1900-01-01
        if isinstance(node, exp.Add) and ta is not None and tb is not None and ta.this in _TS and tb.this in _TS:
            base = exp.cast(exp.Literal.string("1900-01-01"), "timestamp")
            node.set("expression", exp.Paren(this=exp.Sub(this=node.expression, expression=base)))
            return node
        # datetime +/- n Tage
        if ta is not None and ta.this in _TS and cb in (3, 4, 5):
            node.set("expression", exp.Mul(this=exp.Paren(this=node.expression),
                                           expression=exp.Interval(this=exp.Literal.string("1"), unit=exp.var("day"))))
            return node
        if isinstance(node, exp.Add) and (ca == 1 or cb == 1) and not (ca in (3, 4, 5, 6) or cb in (3, 4, 5, 6)):
            return exp.DPipe(this=node.this, expression=node.expression, safe=False)
        return node

    if isinstance(node, exp.Anonymous) and node.expressions:
        fn = node.name.lower()
        arg_cat = category(_type(node.expressions[0], ctx))
        if fn == "to_char" and arg_cat == 1:
            return node.expressions[0]       # CONVERT(varchar, text, style): Style wirkt nur auf Datum/Zahl
        if fn in ("to_date", "to_timestamp") and arg_cat == 6:
            # CONVERT(date, datetime_wert, style): Style wirkt nur auf Strings
            return _cast(node.expressions[0], exp.DataType.build("date" if fn == "to_date" else "timestamp"))
        return node

    if isinstance(node, (exp.Lag, exp.Lead)) and node.args.get("default") is not None:
        t = _type(node.this, ctx)
        d = node.args["default"]
        if t is not None and t.this in _TS | _DATE and _is_num_literal(d) is not None:
            # T-SQL: Zahl -> datetime = Tage seit 1900-01-01
            node.set("default", exp.Add(this=exp.cast(exp.Literal.string("1900-01-01"), t.copy()),
                                        expression=exp.Mul(this=d, expression=exp.Interval(
                                            this=exp.Literal.string("1"), unit=exp.var("day")))))
        else:
            node.set("default", _coerce_list([node.this, d], ctx)[1])
        return node

    if isinstance(node, exp.Sum):
        if category(_type(node.this, ctx)) == 2:
            node.set("this", _cast(node.this, exp.DataType.build("int")))
        return node

    return node


def _leaf_selects(node: exp.Expr) -> list[exp.Select] | None:
    if isinstance(node, exp.Select):
        return [node]
    if isinstance(node, exp.Subquery):
        return _leaf_selects(node.this)
    if isinstance(node, exp.SetOperation):
        left, right = _leaf_selects(node.left), _leaf_selects(node.right)
        return left + right if left is not None and right is not None else None
    return None


def _fix_unions(tree: exp.Expr, ctx: Ctx) -> None:
    """Spaltenweise über alle Zweige einer (verketteten) UNION/EXCEPT/INTERSECT angleichen."""
    tops = [u for u in tree.find_all(exp.SetOperation) if not isinstance(u.parent, exp.SetOperation)]
    for u in tops:
        selects = _leaf_selects(u)
        if not selects or len({len(s.selects) for s in selects}) != 1:
            continue
        for i in range(len(selects[0].selects)):
            projs = [s.selects[i] for s in selects]
            vals = [p.this if isinstance(p, exp.Alias) else p for p in projs]
            new = _coerce_list(vals, ctx)
            # NULL ohne Typ wird in PG zu text (Fehler bei UNION/rekursiven CTEs) -> Typ der anderen Zweige
            known = [t for v in new if not _is_null(v) and not _is_str_literal(v) and (t := _type(v, ctx)) is not None]
            if known:
                target = _target_type(known)
                # auch Spalten ohne bekannten Typ (z.B. CTE-Spalte `NULL AS x`)
                new = [_cast(v, target) if _is_null(v) or (isinstance(v, exp.Column) and _type(v, ctx) is None)
                       else v for v in new]
            for p, old, nv in zip(projs, vals, new):
                if nv is not old:
                    if isinstance(p, exp.Alias):
                        p.set("this", nv)
                    else:
                        p.replace(exp.alias_(nv, p.alias_or_name or f"col{i}"))


def assign_value(value: exp.Expr, target: exp.DataType, ctx: Ctx) -> exp.Expr:
    """Wert für eine Zuweisung an eine Spalte des Typs target (INSERT/UPDATE/MERGE)."""
    t = _type(value, ctx)
    ct, cv = category(target), category(t)
    if _is_null(value) or ct is None:
        return value
    if _is_empty_string(value):
        v = _empty_string_value(target)
        return v if v is not None else value
    if _is_str_literal(value) or cv is None or cv == ct:
        return value
    if ct == 2:
        lit = _is_num_literal(value)
        if lit is not None:
            return exp.Boolean(this=lit.this not in ("0", 0))
        return _cast(value, target)
    if ct == 1:
        return value          # Zahl/Datum -> Text: PostgreSQL hat Zuweisungs-Casts
    return _cast(value, target)


def _annotate_loose(node: exp.Expr, types: TypeSchema) -> None:
    try:
        annotate_types(node, schema=types.schema, dialect="postgres")
    except Exception:  # noqa: BLE001
        pass


def coerce_assignments(tree: exp.Expr, types: TypeSchema, ctx: Ctx) -> None:
    """INSERT (VALUES/SELECT), UPDATE SET und MERGE: Werte auf die Typen der Zielspalten casten."""
    if isinstance(tree, (exp.Insert, exp.Update, exp.Merge)):
        target = tree.this.this if isinstance(tree.this, exp.Schema) else tree.this
    else:
        return
    if not isinstance(target, exp.Table) or not target.args.get("db"):
        return
    cols = types.mapping.get(target.db, {}).get(target.name)
    if not cols:
        return

    def tt(col: exp.Expr) -> exp.DataType | None:
        name = col.name if isinstance(col, (exp.Column, exp.Identifier)) else None
        return exp.DataType.build(cols[name], dialect="postgres") if name in cols else None

    def fix_rows(col_list: list[exp.Expr], source: exp.Expr | None) -> None:
        if source is None:
            return
        if isinstance(source, exp.Values):
            for row in source.expressions:
                if isinstance(row, exp.Tuple):
                    _annotate_loose(row, types)
                    row.set("expressions", [assign_value(v, t, ctx) if (t := tt(c)) is not None else v
                                            for c, v in zip(col_list, row.expressions)])
        elif isinstance(source, exp.Tuple):
            _annotate_loose(source, types)
            source.set("expressions", [assign_value(v, t, ctx) if (t := tt(c)) is not None else v
                                       for c, v in zip(col_list, source.expressions)])
        elif isinstance(source, exp.Select):
            for c, p in zip(col_list, source.selects):
                t = tt(c)
                v = p.this if isinstance(p, exp.Alias) else p
                if t is None:
                    continue
                nv = assign_value(v, t, ctx)
                if nv is not v:
                    if isinstance(p, exp.Alias):
                        p.set("this", nv)
                    else:
                        p.replace(nv)

    def fix_set(eqs: list[exp.Expr]) -> None:
        for eq in eqs:
            if isinstance(eq, exp.EQ) and (t := tt(eq.this)) is not None:
                _annotate_loose(eq.expression, types)
                eq.set("expression", assign_value(eq.expression, t, ctx))

    target_alias = (target.alias or target.name)

    def type_target_columns(node: exp.Expr | None, allow_unqualified: bool) -> None:
        if node is None:
            return
        for col in node.find_all(exp.Column):
            if (col.table == target_alias or (allow_unqualified and not col.table)) and col.name in cols \
                    and (col.type is None or col.type.this == T.UNKNOWN):
                col.type = exp.DataType.build(cols[col.name], dialect="postgres")

    def fix_conditions(node: exp.Expr | None) -> None:
        if node is None:
            return
        for n in reversed(list(node.walk())):
            new = _fix(n, ctx)
            if new is not n and n is not node:
                n.replace(new)

    if isinstance(tree, exp.Insert) and not isinstance(tree.this, exp.Schema) and tree.expression is not None:
        # T-SQL: INSERT ohne Spaltenliste überspringt die Identity-Spalte
        ident = types.identity.get((target.db, target.name), set())
        names = [c for c in cols if c not in ident]
        tree.set("this", exp.Schema(this=target.copy(), expressions=[exp.to_identifier(c) for c in names]))

    if isinstance(tree, (exp.Update, exp.Delete)):
        where = tree.args.get("where")
        if where is not None:
            _annotate_loose(where, types)
        type_target_columns(tree, allow_unqualified=True)
        if where is not None:
            fix_conditions(where)

    if isinstance(tree, exp.Merge):
        # Typen der Quellspalten aus der (bereits annotierten) USING-Unterabfrage übernehmen
        using = tree.args.get("using")
        if isinstance(using, exp.Subquery) and using.alias:
            sel = using.this
            while isinstance(sel, exp.SetOperation):
                sel = sel.left
            if isinstance(sel, exp.Select):
                src_types = {p.alias_or_name: p.type for p in sel.selects if p.type is not None}
                for part in (tree.args["whens"], tree.args.get("on")):
                    for col in part.find_all(exp.Column):
                        if col.table == using.alias and col.name in src_types:
                            col.type = src_types[col.name].copy()
        type_target_columns(tree.args.get("on"), allow_unqualified=False)
        type_target_columns(tree.args["whens"], allow_unqualified=False)
        fix_conditions(tree.args.get("on"))
        for w in tree.args["whens"].expressions:
            fix_conditions(w.args.get("condition"))

    if isinstance(tree, exp.Insert):
        col_list = tree.this.expressions if isinstance(tree.this, exp.Schema) else []
        if col_list:
            fix_rows(col_list, tree.expression)
    elif isinstance(tree, exp.Update):
        fix_set(tree.expressions)
    else:
        for w in tree.args["whens"].expressions:
            then = w.args.get("then")
            if isinstance(then, exp.Update):
                fix_set(then.expressions)
            elif isinstance(then, exp.Insert):
                col_list = then.this.expressions if isinstance(then.this, exp.Tuple) else []
                fix_rows(col_list, then.expression)


def coerce(tree: exp.Expr, types: TypeSchema, ctx: Ctx) -> exp.Expr:
    """Qualifizieren, Typen annotieren, Konflikte auflösen. Bei Fehlern: Baum unverändert."""
    try:
        q = qualify(tree.copy(), schema=types.schema, dialect="postgres", expand_stars=True, identify=False,
                    quote_identifiers=False, validate_qualify_columns=False, expand_alias_refs=False,
                    allow_partial_qualification=True)
        annotate_types(q, schema=types.schema, dialect="postgres")
    except Exception as e:  # noqa: BLE001 – Inferenz ist best effort
        try:
            # Rückfall: ohne Spaltenqualifizierung (nur explizit qualifizierte Spalten werden typisiert)
            q = qualify(tree.copy(), schema=types.schema, dialect="postgres", expand_stars=False, identify=False,
                        quote_identifiers=False, validate_qualify_columns=False, expand_alias_refs=False,
                        qualify_columns=False)
            annotate_types(q, schema=types.schema, dialect="postgres")
            ctx.warn(f"Typinferenz nur teilweise: {str(e).splitlines()[0][:100]}")
        except Exception:  # noqa: BLE001
            ctx.warn(f"Typinferenz nicht möglich: {str(e).splitlines()[0][:100]}")
            return tree
    nodes = list(q.walk())
    for n in reversed(nodes):
        new = _fix(n, ctx)
        if new is not n:
            if n is q:
                q = new
            else:
                n.replace(new)
    _fix_unions(q, ctx)
    return q


def output_columns(query: exp.Expr) -> dict[str, str]:
    """Spaltentypen einer annotierten Abfrage (für Views als Quelle weiterer Views)."""
    sel = query
    while isinstance(sel, exp.SetOperation):
        sel = sel.left
    if not isinstance(sel, exp.Select):
        return {}
    out = {}
    for s in sel.selects:
        name = s.alias_or_name
        t = s.type
        if name and t is not None and t.this not in (T.UNKNOWN, T.NULL):
            out[name] = t.sql(dialect="postgres")
    return out
