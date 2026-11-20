"""deploy: Zieldatenbank frisch aufbauen (Schemas droppen/anlegen), Objekte in Abhängigkeitsreihenfolge.

* Verwaltete Schemas = Schemas aller Objekte im Manifest, ohne RAW (wenn RAW_DDL=false) und ohne Blacklist.
* Jedes Objekt läuft in einer eigenen Transaktion. Fehler brechen nicht ab:
  - Views/Tabellen, deren Abhängigkeit fehlt oder fehlschlug, werden übersprungen.
  - PL/pgSQL-Funktionen werden trotzdem angelegt (Rumpf wird erst zur Laufzeit geprüft) – mit Hinweis.
* Ergebnis: Konsole + out/deploy_report.json
"""

from __future__ import annotations

import json
from collections import Counter
from datetime import datetime

import click
import psycopg

from .config import Settings
from .deps import topo_order
from .mig import load_manifest
from .model import DEPLOYABLE, TYPES
from .naming import quote

STATE_SCHEMA = "_migration"
# Typen, deren CREATE die referenzierten Objekte sofort auflöst
STRICT_TYPES = {"view", "table"}


def _err(e: Exception) -> str:
    diag = getattr(e, "diag", None)
    msg = str(e).strip().splitlines()[0] if str(e).strip() else type(e).__name__
    if diag is not None and diag.context:
        msg += f" [{diag.context.splitlines()[0]}]"
    return msg


def managed_schemas(manifest: dict, settings: Settings) -> list[str]:
    protected = set(settings.blacklist)
    if not settings.raw_ddl:
        protected.add(settings.raw)
    schemas = {o["pg_schema"] for o in manifest["objects"]}
    return sorted(s for s in schemas if s not in protected)


def run_deploy(settings: Settings, dry_run: bool = False, yes: bool = False) -> bool:
    settings.require("pg_dsn")
    manifest = load_manifest(settings.out_dir)
    objs = {o["key"]: o for o in manifest["objects"]}
    deployable = [k for k, o in objs.items() if o["status"] in DEPLOYABLE]
    deps = {k: [d for d in objs[k]["deps"] if d in objs] for k in deployable}
    order, cyclic = topo_order(deployable, deps, lambda k: (TYPES.index(objs[k]["type"]), k))
    schemas = managed_schemas(manifest, settings)

    if dry_run:
        click.echo(f"Schemas (DROP CASCADE + CREATE): {', '.join(schemas)}")
        for i, k in enumerate(order, 1):
            click.echo(f"{i:5} {objs[k]['type']:<10} {objs[k]['file']}")
        for k in cyclic:
            click.echo(f"ZYKLUS {k}: {objs[k]['deps']}")
        return not cyclic

    with psycopg.connect(settings.pg_dsn, autocommit=True) as conn:
        info = conn.info
        if not yes:
            click.confirm(
                f"Datenbank {info.dbname}@{info.host}:{info.port} – Schemas {', '.join(schemas)} "
                f"werden gelöscht und neu aufgebaut. Fortfahren?", abort=True)
        click.echo(f"Setze {len(schemas)} Schemas zurück ...")
        for s in [*schemas, STATE_SCHEMA]:
            conn.execute(f"DROP SCHEMA IF EXISTS {quote(s)} CASCADE")
        for s in schemas:
            conn.execute(f"CREATE SCHEMA {quote(s)}")
        if not settings.raw_ddl:
            conn.execute(f"CREATE SCHEMA IF NOT EXISTS {quote(settings.raw)}")

        result: dict[str, dict] = {}
        bad: set[str] = {k for k, o in objs.items() if o["status"] not in DEPLOYABLE} | set(cyclic)
        for k in cyclic:
            result[k] = {"status": "failed", "error": f"Zyklische Abhängigkeit: {objs[k]['deps']}"}
        with click.progressbar(order, label="Deploy", show_pos=True,
                               item_show_func=lambda k: k or "") as bar:
            for k in bar:
                o = objs[k]
                missing = [d for d in o["deps"] if d in bad]
                if missing and o["type"] in STRICT_TYPES:
                    result[k] = {"status": "skipped", "error": f"Abhängigkeit fehlt: {', '.join(missing)}"}
                    bad.add(k)
                    continue
                sql = (settings.out_dir / o["file"]).read_text(encoding="utf-8")
                try:
                    with conn.transaction():
                        conn.execute(sql)
                    result[k] = {"status": "deployed"}
                    if missing:
                        result[k]["warning"] = f"Abhängigkeit fehlt (Laufzeitfehler möglich): {', '.join(missing)}"
                except psycopg.Error as e:
                    result[k] = {"status": "failed", "error": _err(e)}
                    bad.add(k)
        for k, o in objs.items():
            if o["status"] not in DEPLOYABLE:
                result[k] = {"status": "not_translated", "error": "; ".join(o["messages"])}

    report = {
        "deployed_at": datetime.now().isoformat(timespec="seconds"),
        "objects": {k: {"type": objs[k]["type"], **v} for k, v in sorted(result.items())},
    }
    (settings.out_dir / "deploy_report.json").write_text(json.dumps(report, indent=2, ensure_ascii=False),
                                                          encoding="utf-8")
    stats = Counter((objs[k]["type"], v["status"]) for k, v in result.items())
    cols = ("deployed", "failed", "skipped", "not_translated")
    click.echo(f"\n{'Typ':<10} " + " ".join(f"{c:>14}" for c in cols))
    for t in TYPES:
        click.echo(f"{t:<10} " + " ".join(f"{stats[(t, c)]:>14}" for c in cols))
    failed = [(k, v) for k, v in result.items() if v["status"] == "failed"]
    for k, v in failed[:30]:
        click.echo(f"  FEHLER {k}: {v['error']}", err=True)
    if len(failed) > 30:
        click.echo(f"  ... {len(failed) - 30} weitere, siehe {settings.out_dir / 'deploy_report.json'}", err=True)
    return not failed
