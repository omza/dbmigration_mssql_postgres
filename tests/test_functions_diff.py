"""Differenzielle Tests: Original-T-SQL-Funktion (MSSQL) vs. Portierung (PG) mit identischen Eingaben."""

from __future__ import annotations

import pytest

from conftest import mssql_create

STRINGS = [
    None, "", " ", "abc", "  abc  ", "abc   ", "a,b,c", "a,,b", "a,b,", ",a", "a, b ,c ,", ",", ",,",
    "a;b;c", "x|y|z", "12ab34", " 1 2 ", "abc123def", "Ä1ö2ü3ß", "²³¹½", "1.5e3", "-12", "007 ",
    "key: value", "{\"a\": 1, \"key\": \"wert\"}", "{'Key':'X Y'}, {'other':2}",
]

ADDRESSES = [
    ("Hauptstraße", "12", "a", "26919", "Brake"),
    ("  Haupt Strasse ", "12", None, "26919", "Brake (Unterweser)"),
    ("Am Deich-v-Weg", None, "Haus 3", "26954", "Nordenham, OT Abbehausen"),
    ("Lange Str.", "5", "/1", "D-26954", "Nordenham b. Bremen"),
    ("Kirchstr", "1", "HTH", "26919", "Ort bei Brake"),
    ("Ölmühlenweg", "7", "ahaus", "26919", "Élan Öhrde"),
    (None, None, None, None, None),
    ("Rue de l'Église", "³", "b", "12 345", "Saint-Étienne"),
    ("STRASSE", "100", "Ä", "abc", "ÄÖÜ"),
]


@pytest.fixture(scope="module")
def functions(mssql_conn, pg_conn):
    for f in ["admin.getdeltavar", "stage.SplitStrings", "stage.json_value_from_key",
              "stage.numeric_value_from_string", "stage.alphanumeric_value_from_string", "stage.adressabgleich"]:
        mssql_create(mssql_conn, f"Programmability/Functions/{f}.UserDefinedFunction.sql")
    return mssql_conn, pg_conn


def ms(conn, sql, *params):
    cur = conn.cursor()
    cur.execute(sql, params)
    return cur.fetchall()


@pytest.mark.parametrize("s", STRINGS)
@pytest.mark.parametrize("delim", [",", ";", "|"])
def test_splitstrings(functions, s, delim):
    m, p = functions
    a = [tuple(r) for r in ms(m, "SELECT Number, Item FROM stage.SplitStrings(?, ?) ORDER BY Number", s, delim)]
    b = p.execute("SELECT number, item FROM stage.splitstrings(%s, %s) ORDER BY number", (s, delim)).fetchall()
    assert a == b


@pytest.mark.parametrize("s", STRINGS)
def test_numeric_value_from_string(functions, s):
    m, p = functions
    a = ms(m, "SELECT stage.numeric_value_from_string(?)", s)[0][0]
    b = p.execute("SELECT stage.numeric_value_from_string(%s)", (s,)).fetchone()[0]
    assert a == b


@pytest.mark.parametrize("s", STRINGS)
def test_alphanumeric_value_from_string(functions, s):
    m, p = functions
    a = ms(m, "SELECT stage.alphanumeric_value_from_string(?)", s)[0][0]
    b = p.execute("SELECT stage.alphanumeric_value_from_string(%s)", (s,)).fetchone()[0]
    assert a == b


@pytest.mark.parametrize("s", STRINGS)
@pytest.mark.parametrize("key", ["key", "KEY", "a", "zzz"])
def test_json_value_from_key(functions, s, key):
    m, p = functions
    a = ms(m, "SELECT stage.json_value_from_key(?, ?)", s, key)[0][0]
    b = p.execute("SELECT stage.json_value_from_key(%s, %s)", (s, key)).fetchone()[0]
    assert a == b


@pytest.mark.parametrize("cond", [
    "changed_at > '{changed_at}'",
    "a > '{x}' AND b >= '{y}'",
    "kein platzhalter",
    "{a}{b}",
    "x > {abc} ",
    "x } y",
    None,
])
def test_getdeltavar(functions, cond):
    m, p = functions
    a = [r[0] for r in ms(m, "SELECT deltavar FROM admin.getdeltavar(?)", cond)]
    b = [r[0] for r in p.execute("SELECT deltavar FROM admin.getdeltavar(%s)", (cond,)).fetchall()]
    assert a == b


@pytest.mark.parametrize("addr", ADDRESSES)
def test_adressabgleich(functions, addr):
    m, p = functions
    a = ms(m, "SELECT stage.adressabgleich(?, ?, ?, ?, ?)", *addr)[0][0]
    b = p.execute("SELECT stage.adressabgleich(%s, %s, %s, %s, %s)", addr).fetchone()[0]
    assert a == b
