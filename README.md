# mssql2pg

Migriert gescriptete MS SQL Server Objekte (täglicher SSMS-Export aus Git) und Tabellendaten nach PostgreSQL (≥ 16, Ziel 18).
Gedacht für wiederholte Migrationsläufe gegen lokale Dev-Instanzen.

```text
clear  →  mig  →  deploy  →  data  (→ validate)
```

## Einrichtung

```bash
uv sync --extra mssql            # mssql-python (kein System-ODBC nötig); alternativ --extra pyodbc
cp .env.example .env             # Zugangsdaten, Quellpfad, Blacklist, RAW-Schema
cp mapping.example.yml mapping.yml
```

Das Git-Repo mit den MSSQL-Skripten wird außerhalb des Tools gepflegt (`git clone`/`git pull`); `MSSQL_SOURCE_DIR` zeigt darauf.
Erwartetes Layout (beliebig tief): `<schema>.<name>.Tables.sql | .View.sql | .StoredProcedure.sql | .UserDefinedFunction.sql`.

Empfohlene Zieldatenbank:

```sql
CREATE DATABASE energydwh TEMPLATE template0 ENCODING 'UTF8'
    LOCALE_PROVIDER icu ICU_LOCALE 'de-DE' LOCALE 'de_DE.UTF-8';
ALTER DATABASE energydwh SET timezone = 'Europe/Berlin';
ALTER DATABASE energydwh SET datestyle = 'ISO, DMY';   -- Datums-Strings wie '31.12.2099' (wie MSSQL mit deutscher Sprache)
CREATE EXTENSION IF NOT EXISTS plpgsql_check;          -- optional, Paket postgresql-18-plpgsql-check
```

PostgreSQL prüft PL/pgSQL-Rümpfe beim Anlegen nur syntaktisch. Ist `plpgsql_check` verfügbar, prüft `deploy` danach jede
übersetzte Funktion statisch (unbekannte Tabellen/Spalten, Typkonflikte). Ohne die Extension gibt es nur einen Hinweis.
Meldungen zu Temp-Tabellen (`tmp_*`) gelten als „nicht prüfbar“, weil diese erst zur Laufzeit entstehen.

## Befehle

| Befehl | Wirkung |
| --- | --- |
| `mssql2pg clear` | löscht `OUT_DIR` (nie `overrides/`) |
| `mssql2pg mig` | konvertiert alle Quellobjekte nach `OUT_DIR/<typ>/<schema>.<name>.sql`, Indizes/FKs nach `OUT_DIR/post/`, schreibt `manifest.json` (Status, Abhängigkeiten, Hinweise) |
| `mssql2pg mig --show schema.name` | konvertiert ein Objekt und gibt es aus (schreibt nichts) |
| `mssql2pg deploy [-y] [--dry-run]` | **löscht** alle verwalteten Schemas (`DROP SCHEMA … CASCADE`) und baut sie in Abhängigkeitsreihenfolge neu auf; Report in `OUT_DIR/deploy_report.json` |
| `mssql2pg data [-t muster] [-x muster] [-j N] [--resume]` | kopiert alle Tabellen außer RAW-Schema/Blacklist (parallel, gechunkt, COPY), danach Indizes, FKs (`NOT VALID` + Validierung), Identity-Reset, `ANALYZE` |
| `mssql2pg check` | prüft die deployten PL/pgSQL-Funktionen mit `plpgsql_check` (Report `OUT_DIR/check_report.json`); läuft bei `deploy` automatisch mit (`--no-check` zum Abschalten) |
| `mssql2pg validate [-l 1..3] [--report r.md]` | Abgleich MSSQL ↔ PG: Zeilenzahl / Spaltenaggregate / Zeilen-Hashes |

Globale Option: `--env-file pfad` (Default `.env`).

## Konfiguration

`.env` – siehe [.env.example](.env.example). Wichtig:

* `SCHEMA_BLACKLIST` – Schemas, die weder migriert, deployt noch kopiert werden. Verweise darauf erzeugen eine Warnung.
* `RAW_SCHEMA` – wird von Talend befüllt; **Daten werden nie kopiert**.
* `RAW_DDL` – `true`: RAW-Tabellen werden von `mig`/`deploy` angelegt (damit abhängige Views deploybar sind);
  `false`: RAW wird gar nicht angefasst (Talend legt die Tabellen an, `deploy` löscht das Schema nicht).

`mapping.yml` – siehe [mapping.example.yml](mapping.example.yml): `renames` (Namen > 63 Bytes), `chunk_columns`, `exclude_objects`, `getdate`.

## Konvertierung

| Objekt | Verfahren |
| --- | --- |
| Tabellen | sqlglot-AST → Modell → PG-DDL. PK/UNIQUE im `CREATE TABLE`, FKs und Indizes erst nach der Datenkopie |
| Views | sqlglot (T-SQL → PG) + eigene Nachbearbeitung |
| Prozeduren | eigener Parser für den Kontrollfluss, DML-Statements über sqlglot → `CREATE FUNCTION … RETURNS void LANGUAGE plpgsql` (Aufruf `SELECT schema.proc(...)`) |
| Funktionen | Skalar → `RETURNS typ`; Multi-Statement-TVF → `RETURNS TABLE (...)` mit `RETURN QUERY` |

Konventionen: Bezeichner lowercase, Quoting nur wenn nötig; Parameter `@x` → `p_x`, Variablen → `v_x`; Temp-Tabellen und Tabellenvariablen → `tmp_x`;
`TRY/CATCH` → `BEGIN … EXCEPTION WHEN OTHERS`; `+` auf Strings → `||`; `DATEDIFF` mit T-SQL-Semantik (Grenzübergänge);
`TRY_CAST` → `pg_input_is_valid()`; `CONVERT(…, style)` → `to_char`/`to_date`/`to_timestamp`; Transaktionssteuerung in Prozeduren wird entfernt (Warnung).

Nicht automatisch übersetzbar (Status `failed`, Override nötig): Cursor, Prozeduren mit Resultsets, Inline-TVFs, PIVOT, GOTO, EXEC mit OUTPUT-Parametern.
Implizite Typkonvertierungen: `mig` ermittelt die Spaltentypen aller Tabellen und (in Abhängigkeitsreihenfolge) Views
und macht T-SQL-Konvertierungen nach Datentyp-Rangfolge explizit (`int = varchar` → Cast, `bit = 1` → `= TRUE`,
`datetime + n` → `+ n * INTERVAL '1 day'`, `ISNULL` vs. `COALESCE`, UNION-Spalten inkl. `NULL`).
Dafür werden Spalten in der Ausgabe qualifiziert und `*` expandiert (semantisch identisch).
In Routinen zusätzlich: Zuweisungen in INSERT/UPDATE/MERGE werden auf die Typen der Zielspalten gebracht
(`''` → 0 bei int, Zahl → boolean), INSERT ohne Spaltenliste bekommt die Spalten ohne Identity,
`MERGE INTO cte` wird auf die Basistabelle umgeschrieben, `CHECKSUM(...)` → `hashtext(ROW(...)::text)`,
`PATINDEX` → `regexp_instr`.

## Overrides

Handgepflegte Dateien unter `overrides/<typ>/<pg_schema>.<pg_name>.sql` (`typ` = `table|view|function|procedure|post`) ersetzen das generierte SQL vollständig.
Overrides ohne Quellobjekt (z.B. Hilfsfunktionen) werden zusätzlich deployt. Abhängigkeiten werden automatisch erkannt,
zusätzlich explizit per Kommentar: `-- depends: core.kunde, util.helper`.

Workflow für fehlgeschlagene Objekte: `out/<typ>/<datei>.sql` enthält die Fehlermeldung und das Original als Kommentar → nach `overrides/` kopieren, portieren, `mig` + `deploy`.

## Deploy-Verhalten

* Reihenfolge: topologisch nach erkannten Referenzen (Token-Analyse), bei Gleichstand Tabellen → Funktionen → Views → Prozeduren.
* Ein Objekt = eine Transaktion. Fehler brechen den Lauf nicht ab: abhängige Views werden übersprungen,
  PL/pgSQL-Funktionen trotzdem angelegt (ihr Rumpf wird erst zur Laufzeit geprüft). Exit-Code ≠ 0 bei Fehlern.
* Zyklen werden gemeldet und nicht deployt.

## Tests

```bash
uv run pytest
```

Unit-Tests mit kleinen Fixtures unter `tests/fixtures/src` (kein Echt-Export im Repo).
