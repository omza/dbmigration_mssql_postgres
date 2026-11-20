from __future__ import annotations

import json

from mssql2pg.mig import run_mig


def _manifest(settings):
    return {o["key"]: o for o in json.loads((settings.out_dir / "manifest.json").read_text())["objects"]}


def test_mig_end_to_end(settings):
    run_mig(settings)
    objs = _manifest(settings)
    assert "secret.geheim" not in objs                       # Blacklist
    assert "raw.import" in objs                              # RAW_DDL=true
    assert objs["core.kunde_gruppe"]["deps"] == ["core.gruppe", "core.kunde"]
    assert any("Blacklist" in m for m in objs["core.kunde_gruppe"]["messages"])
    assert objs["core.kunde_top"]["deps"] == ["core.kunde_gruppe"]
    assert objs["core.cursor_proc"]["status"] == "failed"
    assert (settings.out_dir / "table" / "core.kunde.sql").exists()
    assert (settings.out_dir / "post" / "core.kunde.sql").exists()
    failed = (settings.out_dir / "procedure" / "core.cursor_proc.sql").read_text()
    assert "NICHT ÜBERSETZT" in failed and "-- CREATE PROCEDURE" in failed


def test_raw_ddl_false(settings):
    settings.raw_ddl = False
    run_mig(settings)
    assert "raw.import" not in _manifest(settings)


def test_overrides(settings):
    ov = settings.overrides_dir
    (ov / "procedure").mkdir(parents=True)
    (ov / "procedure" / "core.cursor_proc.sql").write_text(
        "CREATE FUNCTION core.cursor_proc() RETURNS void LANGUAGE sql AS $$ SELECT 1 $$;\n")
    (ov / "function").mkdir()
    (ov / "function" / "util.helper.sql").write_text(
        "-- depends: core.kunde\nCREATE FUNCTION util.helper() RETURNS int LANGUAGE sql AS $$ SELECT 1 $$;\n")
    run_mig(settings)
    objs = _manifest(settings)
    assert objs["core.cursor_proc"]["status"] == "override"
    assert objs["util.helper"]["status"] == "override"
    assert objs["util.helper"]["deps"] == ["core.kunde"]
    assert "LANGUAGE sql" in (settings.out_dir / "procedure" / "core.cursor_proc.sql").read_text()
