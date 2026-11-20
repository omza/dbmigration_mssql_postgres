from pathlib import Path

import pytest

from energydwh.naming import ident, pg_name
from energydwh.tables import load_tables, parse_table_file, render_create, render_fks, render_indexes
from energydwh.typemap import pg_type

ROOT = Path(__file__).resolve().parents[1]
TABLES = ROOT / "energydwh-main" / "Tables"


def test_all_tables_parse():
    tables = load_tables(TABLES)
    assert len(tables) == 207  # 208 minus dbo.sysdiagrams
    for t in tables:
        render_create(t)  # darf nicht werfen (Typen/Defaults vollständig gemappt)


def test_composite_fk(tmp_path):
    p = tmp_path / "x.sql"
    p.write_text(
        "CREATE TABLE [core].[kunden]\n(\n    [id] [sys].[int] NOT NULL\n);\n\n"
        "ALTER TABLE [core].[kunden]\nADD CONSTRAINT [fk_k]\n"
        "FOREIGN KEY ([id_mandant], [id_kundengruppe])\n"
        "REFERENCES [core].[kundengruppen] ([id_mandant], [id_kundengruppe]);"
    )
    t = parse_table_file(p)
    fk = t.fks[0]
    assert (fk.ref_schema, fk.ref_table) == ("core", "kundengruppen")
    assert fk.columns == ["id_mandant", "id_kundengruppe"]
    assert "REFERENCES core.kundengruppen (id_mandant, id_kundengruppe)" in render_fks(t)


def test_index_include_dedup(tmp_path):
    p = tmp_path / "x.sql"
    p.write_text(
        "CREATE TABLE [core].[g]\n(\n    [a] [sys].[int] NOT NULL\n);\n\n"
        "CREATE NONCLUSTERED INDEX [ix]\nON [core].[g] ([a] ASC, [b] DESC)\nINCLUDE ([a], [c]);"
    )
    sql = render_indexes(parse_table_file(p))
    assert "ON core.g (a, b DESC)" in sql
    assert "INCLUDE (c)" in sql


@pytest.mark.parametrize("mssql,pg", [
    ("[sys].[datetime]", "timestamp(3)"),
    ("[sys].[tinyint]", "smallint"),
    ("varchar(MAX)", "text"),
    ("nvarchar(50)", "varchar(50)"),
    ("char(10)", "char(10)"),
    ("decimal(13,2)", "numeric(13,2)"),
    ("varbinary(MAX)", "bytea"),
    ("[sys].[float]", "double precision"),
    ("[sys].[sysname]", "varchar(128)"),
])
def test_typemap(mssql, pg):
    assert pg_type(mssql) == pg


@pytest.mark.parametrize("raw,expected", [
    ("[SchuleGruenerWeg]", "schulegruenerweg"),
    ("[abnahmestelle_straße]", "abnahmestelle_straße"),
    ("[Werksprüf_/Eichung?]", '"werksprüf_/eichung?"'),
    ("[< 3000 bis 6000 kWh]", '"< 3000 bis 6000 kwh"'),
    ("[2020]", '"2020"'),
    ("[user]", '"user"'),
    ("[name]", "name"),
])
def test_ident(raw, expected):
    assert ident(raw) == expected


def test_long_ident_rename():
    assert len(pg_name("[Abgleich_mit_Rainer_Hoffs_Liste_ob_vorhanden_NV_bei_ihm_nicht_geführt]").encode()) <= 63
    with pytest.raises(ValueError):
        pg_name("x" * 64)
