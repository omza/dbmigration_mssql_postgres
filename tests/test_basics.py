from __future__ import annotations

from pathlib import Path

import pytest

from mssql2pg import naming
from mssql2pg.config import Mapping
from mssql2pg.deps import find_references, topo_order
from mssql2pg.source import classify, load_sources, split_batches
from mssql2pg.typemap import pg_type

from .conftest import FIXTURES


@pytest.mark.parametrize("mssql,pg", [
    ("[sys].[datetime]", "timestamp(3)"), ("sys.bigint", "bigint"), ("varchar(MAX)", "text"),
    ("nvarchar(50)", "varchar(50)"), ("decimal(13, 2)", "numeric(13,2)"), ("bit", "boolean"),
    ("tinyint", "smallint"), ("datetime2(7)", "timestamp(6)"), ("money", "numeric(19,4)"),
    ("varbinary(max)", "bytea"), ("uniqueidentifier", "uuid"),
])
def test_typemap(mssql, pg):
    assert pg_type(mssql) == pg


def test_typemap_unknown():
    with pytest.raises(ValueError):
        pg_type("geography")


def test_naming():
    assert naming.ident("[Kunde Name]") == '"kunde name"'
    assert naming.ident("[Order]") == '"order"'
    assert naming.ident("[Straße]") == "straße"
    with pytest.raises(ValueError):
        naming.pg_name("x" * 64)
    naming.set_renames({"x" * 64: "kurz"})
    assert naming.pg_name("X" * 64) == "kurz"


def test_classify_and_batches():
    assert classify(Path("core.a.b.View.sql")) == ("core", "a.b", "view")
    assert classify(Path("dbo.x.Tables.sql")) == ("dbo", "x", "table")
    assert classify(Path("README.md")) is None
    assert split_batches("SELECT 1\nGO\nSELECT 2\n  go  \n") == ["SELECT 1", "SELECT 2"]


def test_load_sources_filters():
    srcs = load_sources(FIXTURES / "src", blacklist={"secret"}, exclude=["core.cursor_*"], skip_schemas={"raw"})
    keys = {s.key for s in srcs}
    assert "secret.geheim" not in keys
    assert "raw.import" not in keys
    assert "core.cursor_proc" not in keys
    assert {"core.kunde", "core.kunde_gruppe", "core.load_kunde", "core.f_split"} <= keys


def test_mapping_load(tmp_path):
    f = tmp_path / "m.yml"
    f.write_text("renames:\n  Foo: bar\nchunk_columns:\nexclude_objects: [DBO.X*]\n", encoding="utf-8")
    m = Mapping.load(f)
    assert m.renames == {"foo": "bar"} and m.chunk_columns == {} and m.exclude_objects == ["dbo.x*"]
    f.write_text("unbekannt: 1\n", encoding="utf-8")
    with pytest.raises(ValueError):
        Mapping.load(f)


def test_find_references():
    known = {"core.kunde": "core.kunde", "core.gruppe": "core.gruppe", "dbo.v": "dbo.v"}
    refs, schemas = find_references(
        "SELECT * FROM [core].[kunde] k JOIN db.core.gruppe g ON 1=1 JOIN v ON 1=1 WHERE x = 'core.kunde2'",
        known, "core.self")
    assert refs == {"core.kunde", "core.gruppe", "dbo.v"}
    assert "core" in schemas


def test_topo_order_and_cycle():
    order, cyc = topo_order(["a", "b", "c", "d", "e"],
                            {"a": ["b"], "b": ["c"], "d": ["e"], "e": ["d"]}, lambda k: k)
    assert order == ["c", "b", "a"]
    assert cyc == ["d", "e"]
