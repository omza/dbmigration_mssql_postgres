"""Datenkopie MSSQL -> PostgreSQL.

Ablauf je Tabelle:
  1. Chunks planen (Range über eine Integer-/Datums-Spalte, Default: einspaltiger PK)
  2. Chunks parallel kopieren (Prozess-Pool). Ein Chunk = eine PG-Transaktion
     (COPY + Statuseintrag), dadurch ist ein Abbruch jederzeit wiederaufsetzbar.
  3. Status in _migration.copy_state

Voraussetzung: Tabellen existieren (mssql2pg deploy), FKs/Indizes noch NICHT (post.py danach).
"""

from __future__ import annotations

import fnmatch
import multiprocessing
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from dataclasses import dataclass
from datetime import date, datetime, timedelta

import click
import psycopg

from . import mssql
from .naming import quote
from .convert.tables import Table
from .typemap import base_kind

_STATE_DDL = """
CREATE SCHEMA IF NOT EXISTS _migration;
CREATE TABLE IF NOT EXISTS _migration.copy_state (
    tbl          text NOT NULL,
    chunk        integer NOT NULL,
    n_chunks     integer NOT NULL,
    predicate    text,
    rows_copied  bigint,
    nul_removed  bigint,
    seconds      numeric(12,2),
    finished_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (tbl, chunk)
);
"""


@dataclass(frozen=True)
class Chunk:
    table: Table
    index: int
    n_chunks: int
    mssql_where: str          # WHERE-Bedingung für MSSQL ('' = alles)
    params: tuple             # Parameter für die WHERE-Bedingung
    pg_where: str = ""        # gleiche Bedingung für PG (Chunk vor dem Kopieren leeren -> idempotent)

    @property
    def key(self) -> str:
        return self.table.key


# --------------------------------------------------------------------------- Planung


def _chunk_column(t: Table, overrides: dict[str, str]) -> str | None:
    """-> PG-Spaltenname für die Chunk-Aufteilung."""
    if t.key in overrides:
        return overrides[t.key].lower()
    pk = t.primary_key
    if pk and len(pk.columns) == 1:
        col = t.column(pk.columns[0])
        if col is not None and base_kind(col.pg_type) in ("int", "date", "ts"):
            return col.pg_name
    return None


def plan_chunks(conn, t: Table, chunk_rows: int, overrides: dict[str, str]) -> list[Chunk]:
    cur = conn.cursor()
    cur.execute(f"SELECT COUNT_BIG(*) FROM {t.mssql_qualified}")
    total = cur.fetchone()[0]
    colname = _chunk_column(t, overrides)
    if total <= chunk_rows or colname is None:
        return [Chunk(t, 0, 1, "", ())]

    col = t.column(colname)
    if col is None:
        raise click.ClickException(f"{t.pg_qualified}: Chunk-Spalte {colname!r} existiert nicht")
    kind = base_kind(col.pg_type)
    if kind not in ("int", "date", "ts"):
        raise click.ClickException(f"{t.pg_qualified}: Chunk-Spalte {colname!r} muss int/date/datetime sein")
    c = f"[{col.name}]"
    pc = quote(col.pg_name)
    cur.execute(f"SELECT MIN({c}), MAX({c}) FROM {t.mssql_qualified}")
    lo, hi = cur.fetchone()
    n = max(1, -(-total // chunk_rows))
    if lo is None:
        return [Chunk(t, 0, 1, "", ())]

    bounds: list = []
    if kind == "int":
        step = max(1, -(-(hi - lo + 1) // n))
        bounds = list(range(lo, hi + 1, step)) + [hi + 1]
    else:
        lo_dt = datetime.combine(lo, datetime.min.time()) if type(lo) is date else lo
        hi_dt = datetime.combine(hi, datetime.min.time()) if type(hi) is date else hi
        step = max((hi_dt - lo_dt) / n, timedelta(seconds=1))
        bounds = [lo_dt + i * step for i in range(n)] + [hi_dt + timedelta(days=1)]
        if kind == "date":
            bounds = sorted({b.date() for b in bounds})

    chunks = [
        Chunk(t, i, 0, f"{c} >= ? AND {c} < ?", (bounds[i], bounds[i + 1]), f"{pc} >= %s AND {pc} < %s")
        for i in range(len(bounds) - 1)
    ]
    if col.nullable:
        chunks.append(Chunk(t, len(chunks), 0, f"{c} IS NULL", (), f"{pc} IS NULL"))
    return [Chunk(t, ch.index, len(chunks), ch.mssql_where, ch.params, ch.pg_where) for ch in chunks]


# --------------------------------------------------------------------------- Kopie (Worker)


def _converter(kind: str):
    if kind == "text":
        def conv(v, stats):
            if v is not None and "\x00" in v:
                stats[0] += 1
                return v.replace("\x00", "")
            return v
        return conv
    if kind == "bool":
        return lambda v, stats: None if v is None else bool(v)
    return None


def copy_chunk(ch: Chunk, mssql_conn_str: str, pg_dsn: str, fetch_size: int) -> tuple[str, int, int, int, float]:
    t = ch.table
    started = time.monotonic()
    src_cols = ", ".join(f"[{c.name.replace(']', ']]')}]" for c in t.columns)
    dst_cols = ", ".join(quote(c.pg_name) for c in t.columns)
    convs = [_converter(base_kind(c.pg_type)) for c in t.columns]
    conv_idx = [(i, f) for i, f in enumerate(convs) if f]
    sql = f"SELECT {src_cols} FROM {t.mssql_qualified}"
    if ch.mssql_where:
        sql += f" WHERE {ch.mssql_where}"

    stats = [0]
    rows = 0
    src = mssql.connect(mssql_conn_str)
    try:
        cur = src.cursor()
        cur.execute(sql, ch.params) if ch.params else cur.execute(sql)
        with psycopg.connect(pg_dsn) as pg:
            with pg.transaction():
                if ch.n_chunks == 1:
                    pg.execute(f"TRUNCATE {t.pg_qualified}")
                else:
                    pg.execute(f"DELETE FROM {t.pg_qualified} WHERE {ch.pg_where}", ch.params)
                with pg.cursor().copy(f"COPY {t.pg_qualified} ({dst_cols}) FROM STDIN") as cp:
                    while batch := cur.fetchmany(fetch_size):
                        for r in batch:
                            if conv_idx:
                                r = list(r)
                                for i, f in conv_idx:
                                    r[i] = f(r[i], stats)
                            cp.write_row(r)
                        rows += len(batch)
                secs = time.monotonic() - started
                pg.execute(
                    "INSERT INTO _migration.copy_state (tbl, chunk, n_chunks, predicate, rows_copied, nul_removed, seconds)"
                    " VALUES (%s,%s,%s,%s,%s,%s,%s)"
                    " ON CONFLICT (tbl, chunk) DO UPDATE SET n_chunks=EXCLUDED.n_chunks, predicate=EXCLUDED.predicate,"
                    " rows_copied=EXCLUDED.rows_copied, nul_removed=EXCLUDED.nul_removed,"
                    " seconds=EXCLUDED.seconds, finished_at=now()",
                    (ch.key, ch.index, ch.n_chunks, f"{ch.mssql_where} {ch.params}".strip(), rows, stats[0], round(secs, 2)),
                )
    finally:
        src.close()
    return ch.key, ch.index, rows, stats[0], time.monotonic() - started


# --------------------------------------------------------------------------- Orchestrierung


def select_tables(tables: list[Table], patterns: tuple[str, ...], excludes: tuple[str, ...]) -> list[Table]:
    out = [t for t in tables if not patterns or any(fnmatch.fnmatch(t.key, p.lower()) for p in patterns)]
    return [t for t in out if not any(fnmatch.fnmatch(t.key, p.lower()) for p in excludes)]


def run_copy(
    tables: list[Table],
    mssql_conn_str: str,
    pg_dsn: str,
    workers: int,
    chunk_rows: int,
    fetch_size: int,
    resume: bool,
    overrides: dict[str, str],
    dry_run: bool,
) -> None:
    with psycopg.connect(pg_dsn, autocommit=True) as pg:
        pg.execute(_STATE_DDL)
        if not resume and not dry_run:
            keys = [t.key for t in tables]
            pg.execute("DELETE FROM _migration.copy_state WHERE tbl = ANY(%s)", (keys,))
        done = {(r[0], r[1], r[2]) for r in pg.execute("SELECT tbl, chunk, n_chunks FROM _migration.copy_state")}

    click.echo(f"Plane Chunks für {len(tables)} Tabellen ...")
    src = mssql.connect(mssql_conn_str)
    todo: list[Chunk] = []
    try:
        for t in tables:
            chunks = plan_chunks(src, t, chunk_rows, overrides)
            pending = [c for c in chunks if (c.key, c.index, c.n_chunks) not in done]
            if dry_run:
                click.echo(f"  {chunks[0].key}: {len(chunks)} Chunk(s), offen {len(pending)}")
            elif len(pending) == len(chunks) and len(chunks) > 1:
                # Neustart einer gechunkten Tabelle: einmal vorab leeren (Chunks löschen nicht selbst)
                with psycopg.connect(pg_dsn, autocommit=True) as pg:
                    pg.execute(f"TRUNCATE {t.pg_qualified}")
            elif 0 < len(pending) < len(chunks) and len(chunks) > 1:
                # Resume: Chunk-Grenzen müssen identisch sein, sonst drohen Duplikate
                with psycopg.connect(pg_dsn, autocommit=True) as pg:
                    n_prev = pg.execute("SELECT max(n_chunks) FROM _migration.copy_state WHERE tbl=%s",
                                        (chunks[0].key,)).fetchone()[0]
                if n_prev is not None and n_prev != len(chunks):
                    raise click.ClickException(
                        f"{chunks[0].key}: Chunk-Plan hat sich geändert ({n_prev} -> {len(chunks)}). "
                        "Ohne --resume neu kopieren."
                    )
            todo.extend(pending)
    finally:
        src.close()
    if dry_run:
        return

    # große Chunks zuerst ist nicht bekannt -> gechunkte Tabellen zuerst, damit sie parallelisiert werden
    todo.sort(key=lambda c: -c.n_chunks)
    click.echo(f"Kopiere {len(todo)} Chunks mit {workers} Workern ...")
    total_rows = 0
    errors: list[str] = []
    t0 = time.monotonic()
    # spawn statt fork: der native MSSQL-Treiber im Elternprozess (Chunk-Planung) darf nicht vererbt werden
    with ProcessPoolExecutor(max_workers=workers, mp_context=multiprocessing.get_context("spawn")) as ex:
        futs = {ex.submit(copy_chunk, c, mssql_conn_str, pg_dsn, fetch_size): c for c in todo}
        for f in as_completed(futs):
            c = futs[f]
            try:
                key, idx, rows, nul, secs = f.result()
            except Exception as e:  # noqa: BLE001 – alle Fehler sammeln, Rest weiterkopieren
                errors.append(f"{c.key} [{c.index + 1}/{c.n_chunks}]: {e}")
                click.echo(f"  FEHLER {c.key} [{c.index + 1}/{c.n_chunks}]: {e}", err=True)
                continue
            total_rows += rows
            warn = f"  ({nul} Werte mit NUL-Bytes bereinigt)" if nul else ""
            click.echo(f"  ok  {key} [{idx + 1}/{c.n_chunks}] {rows:>12,} Zeilen {secs:7.1f}s{warn}")
    click.echo(f"{total_rows:,} Zeilen in {time.monotonic() - t0:.0f}s kopiert, {len(errors)} Fehler")
    if errors:
        raise click.ClickException("Kopie unvollständig – nach Behebung mit --resume fortsetzen")
