"""Abgleich MSSQL <-> PostgreSQL (nach der Initialkopie und im Parallelbetrieb).

Stufe 1: Zeilenzahl
Stufe 2: je Spalte Anzahl Nicht-NULL + Summe (numerisch) / min,max (Datum) /
         Summe der Längen (Text) / Summe true (bool) / Summe Bytes (binär) – komplett in der DB
Stufe 3: voller Zeilenvergleich. Reihenfolgeunabhängig (Sortierung CI vs. ICU unterscheidet sich):
         Jede Zeile wird normalisiert und gehasht, Hashes werden in Buckets (nach PK) aufsummiert.
         Nur abweichende Buckets werden in einem zweiten Durchlauf zeilengenau aufgelöst.
"""

from __future__ import annotations

import hashlib
import math
import struct
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from decimal import Decimal

import click
import psycopg

from . import mssql
from .naming import quote
from .tables import Column, Table
from .typemap import base_kind

N_BUCKETS = 4096
MASK64 = (1 << 64) - 1


@dataclass
class Result:
    table: str
    level: int
    ok: bool = True
    rows_mssql: int | None = None
    rows_pg: int | None = None
    diffs: list[str] = field(default_factory=list)


# --------------------------------------------------------------------------- Stufe 2: Aggregate


def _agg_exprs(c: Column) -> tuple[list[str], list[str], str]:
    """(MSSQL-Ausdrücke, PG-Ausdrücke, Vergleichsart) für eine Spalte."""
    m = f"[{c.name.replace(']', ']]')}]"
    p = quote(c.pg_name)
    kind = base_kind(c.pg_type)
    ms = [f"COUNT_BIG({m})"]
    ps = [f"count({p})"]
    if kind in ("int", "numeric"):
        scale = c.pg_type.split(",")[1].rstrip(")") if "," in c.pg_type else "0"
        ms.append(f"SUM(CAST({m} AS DECIMAL(38,{scale})))")
        ps.append(f"sum({p})::numeric")
        return ms, ps, "exact"
    if kind == "float":
        ms.append(f"SUM(CAST({m} AS FLOAT))")
        ps.append(f"sum({p}::float8)")
        return ms, ps, "float"
    if kind in ("date", "ts", "time"):
        ms += [f"MIN({m})", f"MAX({m})"]
        ps += [f"min({p})", f"max({p})"]
        return ms, ps, "exact"
    if kind == "text":
        # LEN ignoriert Leerzeichen am Ende; NUL-Bytes werden bei der Kopie entfernt
        ms.append(f"SUM(CAST(LEN(REPLACE({m} COLLATE Latin1_General_BIN, CHAR(0), '')) AS BIGINT))")
        ps.append(f"sum(length(rtrim({p}::text, ' ')))")
        return ms, ps, "exact"
    if kind == "bool":
        ms.append(f"SUM(CAST({m} AS INT))")
        ps.append(f"count(*) FILTER (WHERE {p})")
        return ms, ps, "exact"
    if kind == "bytes":
        ms.append(f"SUM(CAST(DATALENGTH({m}) AS BIGINT))")
        ps.append(f"sum(octet_length({p}))")
        return ms, ps, "exact"
    return ms, ps, "exact"


def _eq(a, b, how: str) -> bool:
    if a is None or b is None:
        return a is None and b is None or (a in (0, None) and b in (0, None))
    if how == "float":
        return math.isclose(float(a), float(b), rel_tol=1e-9, abs_tol=1e-6)
    if isinstance(a, (int, Decimal)) and isinstance(b, (int, Decimal)):
        return Decimal(a) == Decimal(b)
    return a == b


def level2(t: Table, ms_conn, pg_conn, res: Result) -> None:
    specs = [(c, *_agg_exprs(c)) for c in t.columns]
    ms_sql = "SELECT " + ", ".join(e for _, m, _, _ in specs for e in m) + f" FROM {t.mssql_qualified}"
    pg_sql = "SELECT " + ", ".join(e for _, _, p, _ in specs for e in p) + f" FROM {t.pg_qualified}"
    cur = ms_conn.cursor()
    cur.execute(ms_sql)
    mv = list(cur.fetchone())
    pv = list(pg_conn.execute(pg_sql).fetchone())
    i = 0
    for c, m, _, how in specs:
        names = ["count"] + (["sum"] if len(m) == 2 else ["min", "max"])[: len(m) - 1]
        for name in names:
            if not _eq(mv[i], pv[i], how):
                res.ok = False
                res.diffs.append(f"{c.pg_name}.{name}: mssql={mv[i]!r} pg={pv[i]!r}")
            i += 1


# --------------------------------------------------------------------------- Stufe 3: Zeilen


def _normalizers(t: Table):
    out = []
    for c in t.columns:
        kind = base_kind(c.pg_type)
        is_char = c.pg_type.startswith("char(")
        if kind == "text":
            out.append(
                (lambda v: None if v is None else v.replace("\x00", "").rstrip(" "))
                if is_char else (lambda v: None if v is None else v.replace("\x00", ""))
            )
        elif c.pg_type == "real":
            out.append(lambda v: None if v is None else struct.unpack("f", struct.pack("f", v))[0])
        elif kind == "numeric":
            out.append(lambda v: None if v is None else Decimal(v).normalize())
        elif kind == "bool":
            out.append(lambda v: None if v is None else bool(v))
        elif kind == "bytes":
            out.append(lambda v: None if v is None else bytes(v))
        else:
            out.append(lambda v: v)
    return out


def _h(obj) -> int:
    return int.from_bytes(hashlib.blake2b(repr(obj).encode(), digest_size=8).digest(), "little")


def _stream(cursor, fetch: int):
    while batch := cursor.fetchmany(fetch):
        yield from batch


def _fingerprints(rows, norms, pk_idx: list[int] | None, want: set[int] | None):
    """Bucket-Summen; falls `want` gesetzt: stattdessen Zeilen der gewünschten Buckets sammeln."""
    sums = [0] * N_BUCKETS
    counts = [0] * N_BUCKETS
    collected: dict[int, list] = defaultdict(list)
    for r in rows:
        nr = tuple(f(v) for f, v in zip(norms, r))
        rh = _h(nr)
        b = (_h(tuple(nr[i] for i in pk_idx)) if pk_idx else rh) % N_BUCKETS
        if want is None:
            sums[b] = (sums[b] + rh) & MASK64
            counts[b] += 1
        elif b in want:
            collected[b].append(nr)
    return (sums, counts) if want is None else collected


def level3(t: Table, ms_conn, pg_conn, res: Result, fetch: int, max_diffs: int) -> None:
    norms = _normalizers(t)
    pk = t.primary_key
    names = [c.name for c in t.columns]
    pk_idx = [names.index(c) for c, _ in pk.columns] if pk else None
    ms_sql = "SELECT " + ", ".join(f"[{c.name.replace(']', ']]')}]" for c in t.columns) + f" FROM {t.mssql_qualified}"
    pg_sql = "SELECT " + ", ".join(quote(c.pg_name) for c in t.columns) + f" FROM {t.pg_qualified}"

    def ms_rows():
        cur = ms_conn.cursor()
        cur.execute(ms_sql)
        return _stream(cur, fetch)

    def pg_rows():
        cur = pg_conn.cursor(name="v3")  # serverseitiger Cursor -> streamt
        cur.itersize = fetch
        cur.execute(pg_sql)
        return cur

    ms_fp = _fingerprints(ms_rows(), norms, pk_idx, None)
    with pg_conn.transaction():
        pg_fp = _fingerprints(pg_rows(), norms, pk_idx, None)
    bad = {b for b in range(N_BUCKETS) if ms_fp[0][b] != pg_fp[0][b] or ms_fp[1][b] != pg_fp[1][b]}
    if not bad:
        return
    res.ok = False
    ms_c = _fingerprints(ms_rows(), norms, pk_idx, bad)
    with pg_conn.transaction():
        pg_c = _fingerprints(pg_rows(), norms, pk_idx, bad)
    cols = [c.pg_name for c in t.columns]
    n = 0
    for b in sorted(bad):
        if pk_idx:
            m = {tuple(r[i] for i in pk_idx): r for r in ms_c.get(b, [])}
            p = {tuple(r[i] for i in pk_idx): r for r in pg_c.get(b, [])}
            for key in sorted(set(m) | set(p), key=repr):
                if n >= max_diffs:
                    break
                mr, pr = m.get(key), p.get(key)
                if mr is None:
                    res.diffs.append(f"PK {key}: nur in PG")
                elif pr is None:
                    res.diffs.append(f"PK {key}: fehlt in PG")
                elif mr != pr:
                    d = [f"{cols[i]}: {mr[i]!r} != {pr[i]!r}" for i in range(len(cols)) if mr[i] != pr[i]]
                    res.diffs.append(f"PK {key}: " + "; ".join(d))
                else:
                    continue
                n += 1
        else:
            mc: dict = defaultdict(int)
            for r in ms_c.get(b, []):
                mc[r] += 1
            for r in pg_c.get(b, []):
                mc[r] -= 1
            for r, k in mc.items():
                if k and n < max_diffs:
                    res.diffs.append(f"{'fehlt in PG' if k > 0 else 'nur in PG'} ({abs(k)}x): {r!r}"[:500])
                    n += 1
    if n >= max_diffs:
        res.diffs.append(f"... weitere Abweichungen abgeschnitten (max {max_diffs})")


# --------------------------------------------------------------------------- Orchestrierung


def validate_table(t: Table, level: int, mssql_conn_str: str, pg_dsn: str, fetch: int, max_diffs: int) -> Result:
    res = Result(f"{t.pg_schema}.{t.pg_table}", level)
    ms = mssql.connect(mssql_conn_str)
    try:
        with psycopg.connect(pg_dsn, autocommit=True) as pg:
            cur = ms.cursor()
            cur.execute(f"SELECT COUNT_BIG(*) FROM {t.mssql_qualified}")
            res.rows_mssql = cur.fetchone()[0]
            res.rows_pg = pg.execute(f"SELECT count(*) FROM {t.pg_qualified}").fetchone()[0]
            if res.rows_mssql != res.rows_pg:
                res.ok = False
                res.diffs.append(f"Zeilen: mssql={res.rows_mssql} pg={res.rows_pg}")
            if level >= 2:
                level2(t, ms, pg, res)
            if level >= 3:
                level3(t, ms, pg, res, fetch, max_diffs)
    except Exception as e:  # noqa: BLE001
        res.ok = False
        res.diffs.append(f"FEHLER: {e}")
    finally:
        ms.close()
    return res


def run_validate(tables: list[Table], level_for, mssql_conn_str: str, pg_dsn: str,
                 workers: int, fetch: int, max_diffs: int, report: str | None) -> bool:
    results: list[Result] = []
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = [ex.submit(validate_table, t, level_for(t), mssql_conn_str, pg_dsn, fetch, max_diffs) for t in tables]
        for f in futs:
            r = f.result()
            results.append(r)
            status = "ok  " if r.ok else "DIFF"
            click.echo(f"  {status} L{r.level} {r.table:<70} {r.rows_mssql!s:>12} / {r.rows_pg!s:<12}")
            for d in r.diffs[:5]:
                click.echo(f"         {d}")
            if len(r.diffs) > 5:
                click.echo(f"         ... {len(r.diffs) - 5} weitere (siehe Report)")
    bad = [r for r in results if not r.ok]
    click.echo(f"{len(results) - len(bad)} Tabellen ok, {len(bad)} mit Abweichungen")
    if report:
        with open(report, "w", encoding="utf-8") as fh:
            fh.write("# Validierungsreport\n\n| Tabelle | Stufe | Zeilen MSSQL | Zeilen PG | Status |\n|---|---|---|---|---|\n")
            for r in results:
                fh.write(f"| {r.table} | {r.level} | {r.rows_mssql} | {r.rows_pg} | {'ok' if r.ok else 'DIFF'} |\n")
            for r in bad:
                fh.write(f"\n## {r.table}\n\n" + "".join(f"- {d}\n" for d in r.diffs))
        click.echo(f"Report: {report}")
    return not bad
