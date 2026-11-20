"""Differenzielle Tests der Talend-Schnittstelle (admin.*): Original-SP (MSSQL) vs. Portierung (PG).

Jede Seite bekommt dieselben Aufrufe auf demselben Datenstand. Verglichen werden Result-Sets
und die betroffenen Tabelleninhalte (ohne Zeitstempel, die "jetzt" enthalten).
"""

from __future__ import annotations

import pytest

from conftest import assert_same_rows, both, mssql_create, rows_ms, rows_pg

PROCS = ["admin.start_load", "admin.start_unload", "admin.start_transform", "admin.end_transform",
         "admin.load_data_quality_log", "admin.load_load_freshness"]


@pytest.fixture(scope="module")
def env(mssql_conn, pg_conn):
    m, p = mssql_conn, pg_conn
    mssql_create(m, "Programmability/Functions/admin.getdeltavar.UserDefinedFunction.sql")
    for sp in PROCS:
        mssql_create(m, f"Programmability/Stored Procedures/{sp}.StoredProcedure.sql")
    return m, p


# --------------------------------------------------------------------------- start_load

@pytest.mark.parametrize("args", [
    ("full", "SELECT * FROM CREATOR.ENMES", "wilken_enmes", "", "raw"),
    ("delta", "SELECT * FROM CREATOR.ENZPT", "wilken_enzpt", "ZPT_GEAENDERT > '{zpt_geaendert}'", "raw"),
    ("delta", "SELECT * FROM X where a = 1", "WILKEN_ENZPT", "b >= '{ZPT_ANGELEGT}' and c < '{zpt_geaendert}'", "raw"),
    ("delta", "SELECT * FROM X", "wilken_enabn", "d > '{abn_hausnr}'", "raw"),           # Integer-Kriterium
    ("delta", "SELECT * FROM X", "gibt_es_nicht", "x > '{y}'", "raw"),                  # -> delta_init
    ("delta", "SELECT * FROM X", "kalender", "z > '{tag}'", "core"),                    # date-Spalte
])
def test_start_load(env, args):
    m, p = env
    a = rows_ms(m, "EXEC admin.start_load ?, ?, ?, ?, ?", *args)
    b = rows_pg(p, "SELECT * FROM admin.start_load(%s, %s, %s, %s, %s)", args)
    assert len(a) == len(b) == 1
    assert a[0][1:] == b[0][1:]                       # src_query, load_type (load_id ist systemabhängig)
    ms_log = rows_ms(m, "SELECT load_type, src_query, dest_table, load_status FROM admin.load_log WHERE load_id = ?", a[0][0])
    pg_log = rows_pg(p, "SELECT load_type, src_query, dest_table, load_status FROM admin.load_log WHERE load_id = %s", (b[0][0],))
    assert ms_log == pg_log


def test_start_unload(env):
    m, p = env
    args = ("job_x", "SELECT 1", "sftp", "a@b.de")
    a = rows_ms(m, "EXEC admin.start_unload ?, ?, ?, ?", *args)
    b = rows_pg(p, "SELECT * FROM admin.start_unload(%s, %s, %s, %s)", args)
    assert a[0][1:] == b[0][1:]
    assert rows_ms(m, "SELECT unload_job, destination, recipient, unload_status FROM admin.unload_log WHERE unload_id = ?", a[0][0]) \
        == rows_pg(p, "SELECT unload_job, destination, recipient, unload_status FROM admin.unload_log WHERE unload_id = %s", (b[0][0],))


# --------------------------------------------------------------------------- start/end_transform

TRIGGERS = """INSERT INTO admin.transform_log (load_id, transform_job_id, transform_source, transform_triggered_at, transform_status)
VALUES (900001, -1, 'wilken_enzpt', '2026-11-18 10:00:00', 0),
       (900002, -1, 'WILKEN_ENABN', '2026-11-18 10:00:00', 0),
       (900003, -1, 'wilken_enmnd', '2026-11-18 10:00:00', 0)"""

TLOG = "SELECT load_id, transform_job_id, transform_source, transform_status, transform_message FROM admin.transform_log WHERE load_id >= 900000 OR load_id = 0"
LLOG = "SELECT load_id, load_status, load_message FROM admin.load_log WHERE load_id >= 900000"


def test_start_transform_no_need(env):
    m, p = env
    assert rows_ms(m, "EXEC admin.start_transform") == rows_pg(p, "SELECT * FROM admin.start_transform()")


def test_start_end_transform_with_lock(env):
    m, p = env
    # laufende Loads aus test_start_load abschließen, sonst ist alles gesperrt
    both(m, p, "UPDATE admin.load_log SET load_status = 1 WHERE load_status = 0 AND load_id < 900000")
    both(m, p, TRIGGERS)
    # wilken_enmnd wird gerade geladen (Status 0) -> Trigger gesperrt; ältere unvollständige enzpt-Loads
    # werden durch einen erfolgreichen Nachfolger abgebrochen
    for sql_ms, sql_pg in [
        ("SET IDENTITY_INSERT admin.load_log ON; INSERT INTO admin.load_log (load_id, load_type, load_start_at, dest_table, load_status) VALUES "
         "(900101, 'full', '2026-11-18 09:00:00', 'wilken_enmnd', 0), (900102, 'full', '2026-11-18 08:00:00', 'Wilken_Enzpt', 0), "
         "(900103, 'full', '2026-11-18 09:30:00', 'wilken_enzpt', 1); SET IDENTITY_INSERT admin.load_log OFF;",
         "INSERT INTO admin.load_log (load_id, load_type, load_start_at, dest_table, load_status) VALUES "
         "(900101, 'full', '2026-11-18 09:00:00', 'wilken_enmnd', 0), (900102, 'full', '2026-11-18 08:00:00', 'Wilken_Enzpt', 0), "
         "(900103, 'full', '2026-11-18 09:30:00', 'wilken_enzpt', 1)"),
    ]:
        m.cursor().execute(sql_ms)
        p.execute(sql_pg)

    a = rows_ms(m, "EXEC admin.start_transform")
    b = rows_pg(p, "SELECT * FROM admin.start_transform()")
    assert a == b and a[0][0] > 0
    job = a[0][0]
    assert_same_rows(rows_ms(m, TLOG), rows_pg(p, TLOG))
    assert_same_rows(rows_ms(m, LLOG), rows_pg(p, LLOG))

    a = rows_ms(m, "EXEC admin.end_transform ?, 1, '  fertig  '", job)
    b = rows_pg(p, "SELECT * FROM admin.end_transform(%s, 1, '  fertig  ')", (job,))
    assert a == b == []
    assert_same_rows(rows_ms(m, TLOG), rows_pg(p, TLOG))


def test_start_transform_single_sp(env):
    m, p = env
    # Einzel-SP: existiert (MSSQL: Original-SP, PG: Funktion) bzw. existiert nicht
    a = rows_ms(m, "EXEC admin.start_transform 0, '[admin].[start_load]'")
    b = rows_pg(p, "SELECT * FROM admin.start_transform(0, '[admin].[start_load]')")
    assert a == b
    assert rows_ms(m, "EXEC admin.start_transform 0, 'core.gibt_es_nicht'") \
        == rows_pg(p, "SELECT * FROM admin.start_transform(0, 'core.gibt_es_nicht')") \
        == [(-1, "sp does not exist")]


# --------------------------------------------------------------------------- data quality / freshness

def test_load_data_quality_log(env):
    m, p = env
    src = "(SELECT abn_ort AS fehlerbild FROM raw.wilken_enabn WHERE abn_id < 50) x"
    for _ in range(2):   # zweiter Lauf -> MATCHED-Zweig
        a = rows_ms(m, "EXEC admin.load_data_quality_log 'dq', 'wilken', 'abn', 'ort', ?", src)
        b = rows_pg(p, "SELECT * FROM admin.load_data_quality_log('dq', 'wilken', 'abn', 'ort', %s)", (src,))
        assert a == b
    q = "SELECT dqm_job, system, domain, object, failure, count_rows, datum FROM admin.data_quality_log WHERE system = 'wilken'"
    assert_same_rows(rows_ms(m, q), rows_pg(p, q))


def test_load_data_quality_log_error(env):
    m, p = env
    import psycopg

    # Original: erst Result-Set mit der Meldung, dann THROW -> Fehler kommt beim nächsten Result-Set
    cur = m.cursor()
    cur.execute("EXEC admin.load_data_quality_log 'dq', 's', 'd', 'o', 'raw.wilken_enabn'")
    assert "Fehlerbild Spalte nicht gefunden" in cur.fetchall()[0][0]
    with pytest.raises(Exception, match="Fehlerbild Spalte nicht gefunden"):
        cur.nextset()
    with pytest.raises(psycopg.errors.RaiseException, match="Fehlerbild Spalte nicht gefunden"):
        rows_pg(p, "SELECT * FROM admin.load_data_quality_log('dq', 's', 'd', 'o', 'raw.wilken_enabn')")


def test_load_load_freshness(env):
    m, p = env
    # Loads für ein paar raw-Tabellen mit load_at-Spalte anlegen (identisch)
    tables = [r[0] for r in rows_pg(p, """SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = 'load_at' WHERE n.nspname = 'raw' AND c.relkind = 'r'
        ORDER BY 1 LIMIT 3""")]
    assert tables, "keine raw-Tabelle mit load_at in den Testdaten"
    # varchar-load_at (synthetisch 'wert n') auf ein gültiges Datum setzen – sonst scheitert schon das Original
    both(m, p, "UPDATE raw.sharepoint_saganetzaufbau_mfg_uebersicht SET load_at = '2026-11-15 10:00:00'")
    for i, t in enumerate(tables):
        both(m, p, f"""INSERT INTO admin.load_log (load_type, load_start_at, load_end_at, dest_table, load_status)
                      VALUES ('full', '2026-11-0{i + 1} 06:00:00', '2026-11-0{i + 1} 06:05:00', '{t}', 1),
                             ('full', '2026-11-1{i} 06:00:00', '2026-11-1{i} 06:05:00', '{t}', {1 if i else 2})""")
    a = rows_ms(m, "EXEC admin.load_load_freshness")
    b = rows_pg(p, "SELECT * FROM admin.load_load_freshness()")
    # Tabellennamen sind in PG lowercase (Konvention), MSSQL liefert die Originalschreibweise
    lower = lambda rows: [(r[0].lower(),) + r[1:] for r in rows]   # noqa: E731
    assert_same_rows(lower(a), lower(b))
    q = "SELECT dest_table, max_load_at, last_load_id, last_load_at, last_load_status, max_days_age, freshness_ignore FROM admin.load_freshness"
    assert_same_rows(lower(rows_ms(m, q)), lower(rows_pg(p, q)))
