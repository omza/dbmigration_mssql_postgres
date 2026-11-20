"""Gemeinsame Datenstrukturen."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from pathlib import Path

# Objekttypen (= Unterverzeichnisse in out/ und overrides/), in Deploy-Grundreihenfolge
TYPES = ("table", "function", "view", "procedure")

# Manifest-Status
OK, WARN, FAILED, OVERRIDE = "ok", "warn", "failed", "override"
DEPLOYABLE = (OK, WARN, OVERRIDE)


@dataclass
class SourceObject:
    schema: str            # Original-MSSQL-Schema
    name: str              # Original-MSSQL-Name
    type: str              # table | view | function | procedure
    path: Path
    batches: list[str]     # SQL, an GO getrennt

    @property
    def key(self) -> str:
        """Eindeutiger Schlüssel in MSSQL-Notation (lowercase): schema.name"""
        return f"{self.schema}.{self.name}".lower()

    @property
    def sql(self) -> str:
        return "\nGO\n".join(self.batches)


@dataclass
class PgObject:
    key: str               # schema.name (MSSQL, lowercase) – Schlüssel für Abhängigkeiten
    type: str
    pg_schema: str
    pg_name: str
    status: str = OK
    sql: str = ""
    post_sql: str = ""     # nur Tabellen: Indizes/FKs, laufen nach der Datenkopie
    deps: list[str] = field(default_factory=list)
    messages: list[str] = field(default_factory=list)
    source: str = ""

    @property
    def file(self) -> str:
        return f"{self.type}/{self.pg_schema}.{self.pg_name}.sql"

    def warn(self, msg: str) -> None:
        self.messages.append(msg)
        if self.status == OK:
            self.status = WARN

    def fail(self, msg: str) -> None:
        self.messages.append(msg)
        self.status = FAILED

    def manifest_entry(self) -> dict:
        d = asdict(self)
        d.pop("sql")
        d.pop("post_sql")
        d["file"] = self.file
        d["post_file"] = f"post/{self.pg_schema}.{self.pg_name}.sql" if self.post_sql else None
        return d
