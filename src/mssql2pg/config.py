"""Konfiguration: .env (Zugangsdaten, Pfade, Schalter) + optionale mapping.yml (Projektdaten)."""

from __future__ import annotations

from dataclasses import dataclass, field
from functools import cached_property
from pathlib import Path

import yaml
from pydantic_settings import BaseSettings, SettingsConfigDict


@dataclass
class Mapping:
    """Projektspezifisches Wissen, das nicht in die .env passt (mapping.yml)."""

    # Original-Bezeichner (lowercase) -> neuer PG-Name, z.B. für Namen > 63 Bytes
    renames: dict[str, str] = field(default_factory=dict)
    # "schema.tabelle" (PG-Namen) -> Spalte für die Chunk-Aufteilung bei der Datenkopie
    chunk_columns: dict[str, str] = field(default_factory=dict)
    # fnmatch-Muster "schema.objekt" (lowercase), die nie migriert werden
    exclude_objects: list[str] = field(default_factory=list)
    # PG-Ausdruck für GETDATE()/SYSDATETIME() in Defaults und Code
    getdate: str = "localtimestamp"

    @classmethod
    def load(cls, path: Path | None) -> Mapping:
        if path is None or not path.exists():
            return cls()
        data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
        unknown = set(data) - set(cls.__dataclass_fields__)
        if unknown:
            raise ValueError(f"{path}: unbekannte Schlüssel {sorted(unknown)}")
        data = {k: v for k, v in data.items() if v is not None}   # leere YAML-Schlüssel -> Default
        m = cls(**data)
        m.renames = {k.lower(): v for k, v in m.renames.items()}
        m.chunk_columns = {k.lower(): v for k, v in m.chunk_columns.items()}
        m.exclude_objects = [p.lower() for p in m.exclude_objects]
        return m


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # Verbindungen
    pg_dsn: str = ""
    mssql_conn: str = ""

    # Pfade
    mssql_source_dir: Path = Path("../mssql-scripts")
    out_dir: Path = Path("out")
    overrides_dir: Path = Path("overrides")
    mapping_file: Path = Path("mapping.yml")

    # Schemas (kommagetrennt, Original-MSSQL-Namen, case-insensitive)
    schema_blacklist: str = ""
    raw_schema: str = "raw"
    raw_ddl: bool = True

    # Datenkopie
    copy_workers: int = 4
    copy_chunk_rows: int = 5_000_000
    copy_fetch_size: int = 10_000

    @property
    def blacklist(self) -> set[str]:
        return {s.strip().lower() for s in self.schema_blacklist.split(",") if s.strip()}

    @property
    def raw(self) -> str:
        return self.raw_schema.strip().lower()

    @cached_property
    def mapping(self) -> Mapping:
        return Mapping.load(self.mapping_file)

    def require(self, *names: str) -> None:
        missing = [n.upper() for n in names if not getattr(self, n)]
        if missing:
            raise ValueError(f"Fehlende Konfiguration (.env): {', '.join(missing)}")
