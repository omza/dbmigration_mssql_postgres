"""mig: MSSQL-Quellskripte -> PG-DDL in out/ + manifest.json.

Overrides (overrides/<typ>/<pg_schema>.<pg_name>.sql) ersetzen das generierte SQL vollständig.
Overrides ohne passendes Quellobjekt werden als zusätzliche Objekte aufgenommen (z.B. Hilfsfunktionen).
Explizite Abhängigkeiten in Overrides:  -- depends: schema.objekt, schema.objekt2
"""

from __future__ import annotations

import json
import re
import shutil
from collections import Counter
from datetime import datetime
from pathlib import Path

import click

from . import naming
from .config import Settings
from .convert.routines import convert_routine
from .convert.tables import Table, convert_table
from .convert.views import convert_view
from .deps import find_references
from .model import FAILED, OVERRIDE, TYPES, PgObject, SourceObject
from .source import load_sources, read_text

MANIFEST = "manifest.json"
_DEPENDS_RE = re.compile(r"^--\s*depends:\s*(.+)$", re.M | re.I)


def prepare(settings: Settings) -> None:
    naming.set_renames(settings.mapping.renames)


def skip_schemas(settings: Settings) -> set[str]:
    return set() if settings.raw_ddl else {settings.raw}


def sources(settings: Settings) -> list[SourceObject]:
    return load_sources(settings.mssql_source_dir, settings.blacklist, settings.mapping.exclude_objects,
                        skip_schemas(settings))


def source_tables(settings: Settings, include_raw: bool = False) -> list[Table]:
    """Tabellenmodelle direkt aus den Quellskripten (für data/validate)."""
    prepare(settings)
    srcs = load_sources(settings.mssql_source_dir, settings.blacklist, settings.mapping.exclude_objects,
                        set() if include_raw else {settings.raw})
    out = []
    for s in srcs:
        if s.type == "table":
            _, t = convert_table(s, settings.mapping.getdate)
            if t is not None:
                out.append(t)
    return out


def convert(src: SourceObject, getdate: str) -> PgObject:
    if src.type == "table":
        return convert_table(src, getdate)[0]
    if src.type == "view":
        return convert_view(src, getdate)
    return convert_routine(src, getdate)


def apply_overrides(objs: dict[str, PgObject], overrides_dir: Path) -> list[PgObject]:
    """Overrides einspielen. -> Liste der Override-Objekte (für Abhängigkeitsanalyse)."""
    by_file = {o.file: o for o in objs.values()}
    applied = []
    if not overrides_dir.is_dir():
        return applied
    for p in sorted(overrides_dir.rglob("*.sql")):
        rel = p.relative_to(overrides_dir)
        if len(rel.parts) != 2:
            raise click.ClickException(f"Override muss unter overrides/<typ>/<schema>.<name>.sql liegen: {rel}")
        typ, fname = rel.parts
        if typ == "post":
            target = next((o for o in objs.values() if o.type == "table" and f"{o.pg_schema}.{o.pg_name}.sql" == fname), None)
            if target is None:
                raise click.ClickException(f"Post-Override ohne Tabelle: {rel}")
            target.post_sql = read_text(p)
            target.messages.append(f"Post-Override: {rel}")
            continue
        if typ not in TYPES:
            raise click.ClickException(f"Unbekannter Override-Typ {typ!r} ({rel}), erlaubt: {', '.join(TYPES)}, post")
        schema, _, name = fname[:-4].partition(".")
        obj = by_file.get(f"{typ}/{fname}")
        if obj is None:
            obj = PgObject(f"{schema}.{name}", typ, schema, name)
            objs[obj.key] = obj
        obj.sql = read_text(p)
        obj.status = OVERRIDE
        obj.messages = [f"Override: {rel}"] + [f"(generiert: {m})" for m in obj.messages]
        obj.source = obj.source or str(p)
        applied.append(obj)
    return applied


def compute_deps(objs: dict[str, PgObject], srcs: dict[str, SourceObject], overrides: list[PgObject],
                 settings: Settings) -> None:
    known: dict[str, str] = {}
    for o in objs.values():
        known[o.key] = o.key
        known[f"{o.pg_schema}.{o.pg_name}"] = o.key
    override_keys = {o.key for o in overrides}
    for o in objs.values():
        if o.type == "table" and o.key not in override_keys:
            continue   # Tabellen hängen nur über FKs ab -> Post-Phase
        if o.key in override_keys:
            refs, schemas = find_references(o.sql, known, o.key, dialect="postgres", default_schema="public")
            for m in _DEPENDS_RE.finditer(o.sql):
                for d in m.group(1).split(","):
                    d = d.strip().lower()
                    if d in known:
                        refs.add(known[d])
                    elif d:
                        o.messages.append(f"depends: {d} unbekannt")
        else:
            refs, schemas = find_references(srcs[o.key].sql, known, o.key)
        o.deps = sorted(refs)
        bl = schemas & settings.blacklist
        if bl:
            o.warn(f"Referenziert Blacklist-Schema(s): {', '.join(sorted(bl))}")


def _header(o: PgObject) -> str:
    lines = [f"-- {o.type} {o.pg_schema}.{o.pg_name}", f"-- Quelle: {o.source}", f"-- Status: {o.status}"]
    lines += [f"-- Hinweis: {m}" for m in o.messages]
    if o.deps:
        lines.append(f"-- Abhängigkeiten: {', '.join(o.deps)}")
    return "\n".join(lines) + "\n\n"


def run_mig(settings: Settings, only: tuple[str, ...] = (), types: tuple[str, ...] = ()) -> dict:
    prepare(settings)
    out = settings.out_dir
    srcs = {s.key: s for s in sources(settings)}
    objs: dict[str, PgObject] = {}
    with click.progressbar(list(srcs.values()), label="Konvertiere", show_pos=True) as bar:
        for s in bar:
            try:
                objs[s.key] = convert(s, settings.mapping.getdate)
            except ValueError as e:   # z.B. Bezeichner > 63 Bytes
                o = PgObject(s.key, s.type, s.schema.lower(), s.name.lower(), source=str(s.path))
                o.fail(str(e))
                objs[s.key] = o
    overrides = apply_overrides(objs, settings.overrides_dir)
    compute_deps(objs, srcs, overrides, settings)

    if out.exists():
        shutil.rmtree(out)
    for o in objs.values():
        f = out / o.file
        f.parent.mkdir(parents=True, exist_ok=True)
        if o.status == FAILED:
            src = srcs[o.key].sql if o.key in srcs else ""
            body = "-- NICHT ÜBERSETZT – Override anlegen unter overrides/" + o.file + "\n" + \
                "\n".join("-- " + line for line in src.splitlines()) + "\n"
        else:
            body = o.sql
        f.write_text(_header(o) + body, encoding="utf-8")
        if o.post_sql and o.status != FAILED:
            pf = out / "post" / f"{o.pg_schema}.{o.pg_name}.sql"
            pf.parent.mkdir(parents=True, exist_ok=True)
            pf.write_text(o.post_sql, encoding="utf-8")

    manifest = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "source_dir": str(settings.mssql_source_dir),
        "raw_schema": settings.raw,
        "raw_ddl": settings.raw_ddl,
        "schema_blacklist": sorted(settings.blacklist),
        "objects": [o.manifest_entry() for o in sorted(objs.values(), key=lambda o: (TYPES.index(o.type), o.key))],
    }
    (out / MANIFEST).write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")

    stats = Counter((o.type, o.status) for o in objs.values())
    click.echo(f"\n{'Typ':<10} {'ok':>6} {'warn':>6} {'override':>9} {'failed':>7}")
    for t in TYPES:
        click.echo(f"{t:<10} " + " ".join(f"{stats[(t, s)]:>{w}}" for s, w in
                                          (("ok", 6), ("warn", 6), ("override", 9), ("failed", 7))))
    click.echo(f"\nAusgabe: {out}/  (Manifest: {out / MANIFEST})")
    return manifest


def load_manifest(out_dir: Path) -> dict:
    f = out_dir / MANIFEST
    if not f.exists():
        raise click.ClickException(f"{f} fehlt – zuerst `mssql2pg mig` ausführen")
    return json.loads(f.read_text(encoding="utf-8"))
