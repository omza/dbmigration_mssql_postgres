from __future__ import annotations

from pathlib import Path

import pytest

from mssql2pg import naming
from mssql2pg.config import Settings

FIXTURES = Path(__file__).parent / "fixtures"


@pytest.fixture(autouse=True)
def _reset_renames():
    naming.set_renames({})
    yield
    naming.set_renames({})


@pytest.fixture
def settings(tmp_path: Path) -> Settings:
    return Settings(
        _env_file=None,
        mssql_source_dir=FIXTURES / "src",
        out_dir=tmp_path / "out",
        overrides_dir=tmp_path / "overrides",
        mapping_file=tmp_path / "mapping.yml",
        schema_blacklist="secret",
        raw_schema="raw",
        raw_ddl=True,
    )
