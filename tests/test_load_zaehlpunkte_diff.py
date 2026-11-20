"""Differenzieller Test core.load_zaehlpunkte: Original (MSSQL) vs. Portierung (PG) auf identischen Daten.

Voraussetzung: beide Test-DBs haben denselben Datenstand (tests/rebuild_test_pg.sh nach mssql_seed.py).
"""

from __future__ import annotations

import os

import pytest

from conftest import ROOT, assert_same_rows, both, mssql_create, rows_ms, rows_pg

COLS = """id_zp, wilken_zpt_id, id_mandant, meteringcode, id_energieart, id_zp_typ, abnahmestelle_adresse,
ablesetour_nr, wilken_brw_nr, wilken_zpt_ismesslokation, wilken_zpt_komplexemessung, created_at, changed_at,
abnahmestelle_straße, abnahmestelle_hausnummer, abnahmestelle_hausnummer_zusatz, abnahmestelle_plz,
abnahmestelle_ort, abnahmestelle_lat, abnahmestelle_lon, abnahmestelle_location_type, id_abn, id_netz,
abnahmestelle_status, id_spannungsebene, id_spannungsebene_messung, anschlussleistung, installierte_leistung,
gasdruck_mbar, id_lastprofil, id_zaehlverfahren, id_messstellenbetreiber, grundzustaendig_messstellenbetreiber"""

VIEW_COLS = """wilken_mnd_id, wilken_zpt_id, meteringcode, id_energieart, id_zp_typ, abnahmestelle_adresse,
ablesetour_nr, wilken_brw_nr, wilken_zpt_ismesslokation, wilken_zpt_komplexemessung, created_at, changed_at,
abnahmestelle_straße, abnahmestelle_hausnummer, abnahmestelle_hausnummer_zusatz, abnahmestelle_plz,
abnahmestelle_ort, id_abn, id_netz, abnahmestelle_status, id_spannungsebene, id_spannungsebene_messung,
anschlussleistung, installierte_leistung, gasdruck_mbar, id_lastprofil, id_zaehlverfahren,
id_messstellenbetreiber, grundzustaendig_messstellenbetreiber"""


@pytest.fixture(scope="module")
def env(mssql_conn, pg_conn):
    m, p = mssql_conn, pg_conn
    for v in ["stage.wilken_zaehlpunkt", "stage.wilken_zaehlpunkt_geolocation"]:
        mssql_create(m, f"Views/{v}.View.sql")
    mssql_create(m, "Programmability/Stored Procedures/core.load_zaehlpunkte.StoredProcedure.sql")

    # Die MSSQL-Testquelle hat keine FKs (Seed), synthetische IDs sind nicht referenziell konsistent
    # -> auch in PG für die Zieltabelle entfernen, damit beide Seiten gleiche Regeln haben.
    for (fk,) in p.execute("SELECT conname FROM pg_constraint WHERE conrelid = 'core.zaehlpunkte'::regclass AND contype = 'f'").fetchall():
        p.execute(f"ALTER TABLE core.zaehlpunkte DROP CONSTRAINT {fk}")

    # Testdaten realistischer machen (identisch auf beiden Seiten)
    both(m, p, "UPDATE raw.wilken_enzptmessstellenbetreiber SET zmb_grundzustaendig = CASE WHEN zpt_id % 2 = 0 THEN '1' ELSE '0' END")
    both(m, p, "UPDATE raw.wilken_enzptmessstellenbetreiber SET zpt_id = zpt_id % 50, zmb_status = 1")   # mehrere Zeitscheiben je ZP
    both(m, p, "UPDATE raw.wilken_enzpn SET zpt_id = zpt_id % 60")
    # Geolocation: Adressen passend zu core.zaehlpunkte, gültige und ungültige Koordinaten
    both(m, p, "UPDATE raw.address_geolocation SET lat = '53.123456789', lng = ' 8.5 ' WHERE CAST(SUBSTRING(address, 6, 10) AS VARCHAR(10)) LIKE '%1'")
    both(m, p, "UPDATE raw.address_geolocation SET lat = '1e3', lng = '12,5' WHERE CAST(SUBSTRING(address, 6, 10) AS VARCHAR(10)) LIKE '%2'")
    both(m, p, "UPDATE raw.address_geolocation SET lat = '1234.5' WHERE CAST(SUBSTRING(address, 6, 10) AS VARCHAR(10)) LIKE '%3'")
    both(m, p, "UPDATE raw.address_geolocation SET location_type = 'ROOFTOP' WHERE location_type IS NULL")
    return m, p


def compare_target(m, p):
    a = rows_ms(m, f"SELECT {COLS} FROM core.zaehlpunkte")
    b = rows_pg(p, f"SELECT {COLS} FROM core.zaehlpunkte")
    assert len(a) == len(b)
    assert_same_rows(a, b)


def test_view_wilken_zaehlpunkt(env):
    m, p = env
    a = rows_ms(m, f"SELECT {VIEW_COLS} FROM stage.wilken_zaehlpunkt")
    b = rows_pg(p, f"SELECT {VIEW_COLS} FROM stage.wilken_zaehlpunkt")
    assert len(a) > 50, "Testdaten erzeugen zu wenige Zählpunkte"
    assert_same_rows(a, b)


def test_view_geolocation(env):
    m, p = env
    a = rows_ms(m, "SELECT * FROM stage.wilken_zaehlpunkt_geolocation")
    b = rows_pg(p, "SELECT * FROM stage.wilken_zaehlpunkt_geolocation")
    assert_same_rows(a, b)


def test_load_initial(env):
    m, p = env
    m.cursor().execute("EXEC core.load_zaehlpunkte -1, 1")
    p.execute("SELECT core.load_zaehlpunkte(-1, 1)")
    compare_target(m, p)


def test_load_after_changes(env):
    m, p = env
    both(m, p, "UPDATE raw.wilken_enabn SET abn_ort = 'Nordenham' WHERE abn_id % 3 = 0")
    both(m, p, "UPDATE raw.wilken_enzpt SET zpt_geaendert = '2026-11-01 12:00:00' WHERE zpt_id % 4 = 0")
    both(m, p, "DELETE FROM raw.wilken_enzpn WHERE zpt_id % 5 = 0")
    both(m, p, "UPDATE raw.wilken_enzpt SET zpt_id = zpt_id + 10000 WHERE zpt_id % 9 = 0")  # neue ZP -> INSERT
    m.cursor().execute("EXEC core.load_zaehlpunkte -1, 0")
    p.execute("SELECT core.load_zaehlpunkte(-1, 0)")
    compare_target(m, p)


def test_rerun_is_noop(env):
    m, p = env
    before = rows_pg(p, f"SELECT {COLS} FROM core.zaehlpunkte")
    p.execute("SELECT core.load_zaehlpunkte(-1, 0)")
    assert_same_rows(before, rows_pg(p, f"SELECT {COLS} FROM core.zaehlpunkte"))


def test_case_only_change(env):
    """Reine Groß-/Kleinschreibungsänderung. CHECKSUM ist unter CI-Collation dafür blind – im Original
    greift das hier aber nicht: Die Quelle liefert wilken_zpt_id als numeric, das Ziel speichert int,
    CHECKSUM(numeric 9) <> CHECKSUM(int 9) -> MSSQL aktualisiert bei jedem Lauf ALLE Zeilen.
    Ergebnis daher identisch zu IS DISTINCT FROM (PG aktualisiert nur echte Änderungen)."""
    m, p = env
    both(m, p, "UPDATE raw.wilken_enabn SET abn_ort = 'NORDENHAM' WHERE abn_ort = 'Nordenham'")
    m.cursor().execute("EXEC core.load_zaehlpunkte -1, 0")
    p.execute("SELECT core.load_zaehlpunkte(-1, 0)")
    compare_target(m, p)
    pg_n = rows_pg(p, "SELECT count(*) FROM core.zaehlpunkte WHERE abnahmestelle_ort = 'NORDENHAM'")[0][0]
    assert pg_n > 0
