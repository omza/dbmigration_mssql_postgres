from __future__ import annotations

import pytest
import sqlglot

from mssql2pg.convert.common import Ctx, normalize
from mssql2pg.convert.types import TypeSchema, coerce, output_columns


@pytest.fixture
def types() -> TypeSchema:
    ts = TypeSchema()
    ts.add("core", "k", {"id": "int", "name": "varchar(10)", "aktiv": "boolean", "ts": "timestamp(3)",
                         "betrag": "numeric(10,2)"})
    return ts


def _run(sql: str, types: TypeSchema, ctx: Ctx | None = None) -> str:
    return coerce(sqlglot.parse_one(sql, read="postgres"), types, ctx or Ctx()).sql("postgres")


def test_int_vs_varchar(types):
    assert "CAST(a.name AS INT) = a.id" in _run("SELECT 1 AS x FROM core.k a WHERE a.name = a.id", types)


def test_string_literal_untouched(types):
    assert "a.id = '5'" in _run("SELECT 1 AS x FROM core.k a WHERE a.id = '5'", types)


def test_bit_literal(types):
    out = _run("SELECT 1 AS x FROM core.k a WHERE a.aktiv = 1 OR a.aktiv <> 0", types)
    assert "a.aktiv = TRUE" in out and "a.aktiv <> FALSE" in out


def test_datetime_plus_days(types):
    assert "a.ts + (1) * INTERVAL '1 DAY'" in _run("SELECT a.ts + 1 AS t FROM core.k a", types)


def test_string_plus(types):
    assert "a.name || a.name" in _run("SELECT a.name + a.name AS n FROM core.k a", types)


def test_isnull_vs_coalesce(types):
    # ISNULL: Typ des ersten Arguments; COALESCE: höchste Rangfolge (int)
    isnull = sqlglot.parse_one("SELECT ISNULL(a.name, 0) AS n FROM core.k a", read="tsql")
    assert "COALESCE(a.name, CAST(0 AS VARCHAR(10)))" in coerce(isnull, types, Ctx()).sql("postgres")
    assert "COALESCE(CAST(a.name AS INT), 0)" in _run("SELECT COALESCE(a.name, 0) AS n FROM core.k a", types)


def test_union_null_and_mismatch(types):
    out = _run("SELECT a.id AS v FROM core.k a UNION SELECT NULL AS v FROM core.k b UNION SELECT b.name FROM core.k b",
               types)
    assert "CAST(NULL AS INT)" in out and "CAST(b.name AS INT)" in out


def test_convert_style_on_wrong_input(types):
    # Style wirkt in T-SQL nur bei String->Datum bzw. Datum->String
    tree = sqlglot.parse_one("SELECT CONVERT(date, a.ts, 104) AS d, CONVERT(varchar(10), a.name, 104) AS s "
                             "FROM core.k a", read="tsql")
    ctx = Ctx()
    out = coerce(normalize(tree, ctx), types, ctx).sql("postgres")
    assert "CAST(a.ts AS DATE) AS d" in out and "CAST(a.name AS VARCHAR(10)) AS s" in out


def test_variables_not_qualified(types):
    out = _run("SELECT a.id AS id FROM core.k a WHERE a.name = v_x", types, Ctx(var_types={"v_x": "int"}))
    assert "CAST(a.name AS INT) = v_x" in out


def test_output_columns(types):
    q = coerce(sqlglot.parse_one("SELECT a.id, a.name AS n FROM core.k a", read="postgres"), types, Ctx())
    assert output_columns(q) == {"id": "INT", "n": "VARCHAR(10)"}
