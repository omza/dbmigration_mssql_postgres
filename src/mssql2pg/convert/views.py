"""Views: T-SQL CREATE VIEW -> PostgreSQL (sqlglot + common.normalize)."""

from __future__ import annotations

from sqlglot import exp

from ..model import PgObject, SourceObject
from ..naming import pg_name, quote
from .common import Ctx, Unsupported, normalize, parse_one, to_pg
from .types import TypeSchema, coerce, output_columns


def convert_view(src: SourceObject, getdate: str, types: TypeSchema | None = None) -> PgObject:
    obj = PgObject(src.key, "view", pg_name(src.schema), pg_name(src.name), source=str(src.path))
    ctx = Ctx(getdate=getdate)
    try:
        creates = []
        for batch in src.batches:
            tree = parse_one(batch)
            if isinstance(tree, exp.Create) and tree.kind == "VIEW":
                creates.append(tree)
            elif isinstance(tree, exp.Set) or (isinstance(tree, exp.Command) and tree.name.upper() == "SET"):
                continue
            else:
                raise Unsupported(f"Unerwartetes Statement in View-Skript: {batch.strip()[:60]!r}")
        if len(creates) != 1:
            raise Unsupported(f"{len(creates)} CREATE VIEW im Skript")
        tree = creates[0]
        query = tree.expression
        if isinstance(query, exp.Select) and query.args.get("order") and not query.args.get("limit"):
            # T-SQL erlaubt ORDER BY in Views nur mit TOP; PG braucht es nicht
            ctx.warn("ORDER BY in View beibehalten")
        query = normalize(query.copy(), ctx)
        if types is not None:
            query = coerce(query, types, ctx)
            types.add(obj.pg_schema, obj.pg_name, output_columns(query))
        body = to_pg(query)
    except Unsupported as e:
        obj.fail(str(e))
        return obj
    except Exception as e:  # noqa: BLE001
        obj.fail(f"Fehler: {str(e).splitlines()[0]}")
        return obj
    for w in ctx.warnings:
        obj.warn(w)
    obj.sql = f"CREATE VIEW {quote(obj.pg_schema)}.{quote(obj.pg_name)} AS\n{body};\n"
    return obj
