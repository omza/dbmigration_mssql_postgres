-- Override für stage.argos_file_kopf (Original: Views/stage.argos_file_kopf.View.sql)
--
-- T-SQL nutzt PIVOT über die Key-Value-Zeilen aus raw.argos_lastgang (Zeit = Schlüssel, Last = Wert).
-- PostgreSQL kennt kein PIVOT -> bedingte Aggregation, gruppiert nach den übrigen Spalten (filename, load_log_id).
--
-- Semantik wie im Original:
--   * PIVOT vergleicht unter Latin1_General_CI_AS: case-insensitiv, abschließende Leerzeichen zählen nicht
--     -> lower(rtrim(zeit)) = lower('...')
--   * TRY_CONVERT(date, left(x,10), 104) liefert bei ungültigem Inhalt NULL -> Formatprüfung vor to_date
--     (Datumsfehler wie 31.02. würden in PG trotzdem einen Fehler werfen)
--   * Der Join auf core.kalender ist ein INNER JOIN: Dateien ohne gültigen Zeitraum fallen heraus
--   * CAST(... AS int) / 60 ist Ganzzahldivision (in beiden Systemen)

CREATE VIEW stage.argos_file_kopf AS
WITH piv AS (
  SELECT
    d.filename,
    d.load_log_id,
    max(d.last) FILTER (WHERE lower(rtrim(d.zeit)) = lower('Kunde:'))          AS kunde,
    max(d.last) FILTER (WHERE lower(rtrim(d.zeit)) = lower('Kundennummer:'))   AS kundennummer,
    max(d.last) FILTER (WHERE lower(rtrim(d.zeit)) = lower('Zählpunktbez.:'))  AS zaehlpunktbez,
    max(d.last) FILTER (WHERE lower(rtrim(d.zeit)) = lower('MessgeräteNr:'))   AS messgeraetenr,
    max(d.last) FILTER (WHERE lower(rtrim(d.zeit)) = lower('Kanal:'))          AS kanal,
    max(d.last) FILTER (WHERE lower(rtrim(d.zeit)) = lower('OBIS-Kennzahl:'))  AS obis_kennzahl,
    max(d.last) FILTER (WHERE lower(rtrim(d.zeit)) = lower('Zeitraum:'))       AS zeitraum,
    max(d.last) FILTER (WHERE lower(rtrim(d.zeit)) = lower('Faktor:'))         AS faktor,
    max(d.last) FILTER (WHERE lower(rtrim(d.zeit)) = lower('Meßperiode:'))     AS messperiode,
    max(d.last) FILTER (WHERE lower(rtrim(d.zeit)) = lower('Einheit:'))        AS einheit,
    max(d.last) FILTER (WHERE lower(rtrim(d.zeit)) = lower('Daten:'))          AS daten,
    max(d.last) FILTER (WHERE lower(rtrim(d.zeit)) = lower('Energie:'))        AS energie
  FROM raw.argos_lastgang AS d
  GROUP BY d.filename, d.load_log_id
), kopf AS (
  SELECT
    piv.*,
    CASE WHEN left(piv.zeitraum, 10) ~ '^\d{2}\.\d{2}\.\d{4}$'
         THEN to_date(left(piv.zeitraum, 10), 'DD.MM.YYYY') END AS zeitraum_datum
  FROM piv
)
SELECT
  kopf.load_log_id,
  kopf.filename,
  btrim(kopf.kunde, ' ')                              AS kunden_name,
  btrim(kopf.kundennummer, ' ')                       AS kunden_nummer,
  btrim(kopf.zaehlpunktbez, ' ')                      AS meteringcode,
  btrim(kopf.messgeraetenr, ' ')                      AS zaehlernummer,
  CAST(kopf.kanal AS integer)                         AS kanal,
  btrim(kopf.obis_kennzahl, ' ')                      AS obis,
  kopf.zeitraum_datum                                 AS zeitraum,
  cal.tag,
  cal.id_typtag,
  cal.id_zeitumstellung,
  CAST(kopf.faktor AS integer)                        AS wandlerfaktor,
  CAST(kopf.messperiode AS integer) / 60              AS raster_minuten,
  btrim(kopf.einheit, ' ')                            AS messeinheit,
  CAST(kopf.daten AS integer)                         AS anzahl_werte,
  CAST(replace(kopf.energie, ',', '.') AS numeric(18,3)) AS kwh
FROM kopf
JOIN (SELECT DISTINCT tag, id_typtag, id_zeitumstellung FROM core.kalender) AS cal
  ON kopf.zeitraum_datum = cal.tag;
