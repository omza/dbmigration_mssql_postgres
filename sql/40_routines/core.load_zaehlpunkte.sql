-- Quelle: energydwh-main/Programmability/Stored Procedures/core.load_zaehlpunkte.StoredProcedure.sql
-- Pflegt core.zaehlpunkte aus stage.wilken_zaehlpunkt (+ Geolocation).
-- Aufruf: SELECT core.load_zaehlpunkte(-1, 0);   -- verbose = 1: Start/Ende in admin.transform_log_detail
--
-- Muster für alle core.load_*-Portierungen:
--   * Signatur (p_transform_job_id bigint, p_verbose integer DEFAULT 0) RETURNS void
--   * Atomar: Fehler -> alles zurückgerollt, Exception geht an den Aufrufer
--     (core.energydhw_transform_*), der protokolliert. Kein eigenes CATCH-Logging mehr.
--   * MERGE in eine CTE (T-SQL) -> MERGE direkt in die Tabelle
--   * CHECKSUM(a,b,...) != CHECKSUM(...) -> (t.a, t.b, ...) IS DISTINCT FROM (s.a, s.b, ...)
--     Exakter als CHECKSUM: Auch reine Groß-/Kleinschreibungsänderungen (CHECKSUM war unter der
--     CI-Collation blind dafür) und Hash-Kollisionen führen jetzt zum Update.
CREATE OR REPLACE FUNCTION core.load_zaehlpunkte(p_transform_job_id bigint, p_verbose integer DEFAULT 0)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    c_sp CONSTANT text := 'load_zaehlpunkte';
BEGIN
    IF p_verbose = 1 THEN
        PERFORM util.log_detail(p_transform_job_id, c_sp, 'Start');
    END IF;

    MERGE INTO core.zaehlpunkte AS t
    USING (
        SELECT DISTINCT
            zp.wilken_zpt_id AS id_zp,
            mnd.id_mandant,
            zp.wilken_zpt_id,
            zp.meteringcode,
            zp.id_energieart,
            zp.id_zp_typ,
            zp.abnahmestelle_adresse,
            zp.ablesetour_nr,
            zp.wilken_brw_nr,
            zp.wilken_zpt_ismesslokation,
            zp.wilken_zpt_komplexemessung,
            zp.created_at,
            zp.changed_at,
            zp.abnahmestelle_straße,
            zp.abnahmestelle_hausnummer,
            zp.abnahmestelle_hausnummer_zusatz,
            zp.abnahmestelle_plz,
            zp.abnahmestelle_ort,
            loc.abnahmestelle_lat,
            loc.abnahmestelle_lon,
            loc.abnahmestelle_location_type,
            zp.id_abn,
            zp.id_netz,
            zp.abnahmestelle_status,
            zp.id_spannungsebene,
            zp.id_spannungsebene_messung,
            zp.anschlussleistung,
            zp.installierte_leistung,
            zp.gasdruck_mbar,
            zp.id_lastprofil,
            zp.id_zaehlverfahren,
            zp.id_messstellenbetreiber,
            zp.grundzustaendig_messstellenbetreiber
        FROM stage.wilken_zaehlpunkt zp
        JOIN core.mandant mnd
            ON zp.wilken_mnd_id = mnd.wilken_mnd_id
        LEFT JOIN stage.wilken_zaehlpunkt_geolocation loc
            ON zp.wilken_zpt_id = loc.id_zp
    ) AS s
    ON s.id_zp = t.id_zp

    WHEN MATCHED AND (
            t.wilken_zpt_id, t.id_mandant, t.meteringcode, t.id_energieart, t.id_zp_typ,
            t.abnahmestelle_adresse, t.ablesetour_nr, t.wilken_brw_nr, t.wilken_zpt_ismesslokation,
            t.wilken_zpt_komplexemessung, t.created_at, t.changed_at,
            t.abnahmestelle_straße, t.abnahmestelle_hausnummer, t.abnahmestelle_hausnummer_zusatz,
            t.abnahmestelle_plz, t.abnahmestelle_ort,
            t.abnahmestelle_lat, t.abnahmestelle_lon, t.abnahmestelle_location_type,
            t.id_abn, t.id_netz, t.abnahmestelle_status,
            t.id_spannungsebene, t.id_spannungsebene_messung, t.anschlussleistung, t.installierte_leistung,
            t.gasdruck_mbar, t.id_lastprofil, t.id_zaehlverfahren,
            t.id_messstellenbetreiber, t.grundzustaendig_messstellenbetreiber
        ) IS DISTINCT FROM (
            s.wilken_zpt_id, s.id_mandant, s.meteringcode, s.id_energieart, s.id_zp_typ,
            s.abnahmestelle_adresse, s.ablesetour_nr, s.wilken_brw_nr, s.wilken_zpt_ismesslokation,
            s.wilken_zpt_komplexemessung, s.created_at, s.changed_at,
            s.abnahmestelle_straße, s.abnahmestelle_hausnummer, s.abnahmestelle_hausnummer_zusatz,
            s.abnahmestelle_plz, s.abnahmestelle_ort,
            s.abnahmestelle_lat, s.abnahmestelle_lon, s.abnahmestelle_location_type,
            s.id_abn, s.id_netz, s.abnahmestelle_status,
            s.id_spannungsebene, s.id_spannungsebene_messung, s.anschlussleistung, s.installierte_leistung,
            s.gasdruck_mbar, s.id_lastprofil, s.id_zaehlverfahren,
            s.id_messstellenbetreiber, s.grundzustaendig_messstellenbetreiber
        ) THEN
        UPDATE SET
            changed_at = s.changed_at,
            id_mandant = s.id_mandant,
            wilken_zpt_id = s.wilken_zpt_id,
            meteringcode = s.meteringcode,
            id_energieart = s.id_energieart,
            id_zp_typ = s.id_zp_typ,
            abnahmestelle_adresse = s.abnahmestelle_adresse,
            ablesetour_nr = s.ablesetour_nr,
            wilken_brw_nr = s.wilken_brw_nr,
            wilken_zpt_ismesslokation = s.wilken_zpt_ismesslokation,
            wilken_zpt_komplexemessung = s.wilken_zpt_komplexemessung,
            abnahmestelle_straße = s.abnahmestelle_straße,
            abnahmestelle_hausnummer = s.abnahmestelle_hausnummer,
            abnahmestelle_hausnummer_zusatz = s.abnahmestelle_hausnummer_zusatz,
            abnahmestelle_plz = s.abnahmestelle_plz,
            abnahmestelle_ort = s.abnahmestelle_ort,
            abnahmestelle_lat = s.abnahmestelle_lat,
            abnahmestelle_lon = s.abnahmestelle_lon,
            abnahmestelle_location_type = s.abnahmestelle_location_type,
            id_abn = s.id_abn,
            id_netz = s.id_netz,
            abnahmestelle_status = s.abnahmestelle_status,
            id_spannungsebene = s.id_spannungsebene,
            id_spannungsebene_messung = s.id_spannungsebene_messung,
            anschlussleistung = s.anschlussleistung,
            installierte_leistung = s.installierte_leistung,
            gasdruck_mbar = s.gasdruck_mbar,
            id_lastprofil = s.id_lastprofil,
            id_zaehlverfahren = s.id_zaehlverfahren,
            id_messstellenbetreiber = s.id_messstellenbetreiber,
            grundzustaendig_messstellenbetreiber = s.grundzustaendig_messstellenbetreiber

    WHEN NOT MATCHED THEN
        INSERT (
            id_zp, wilken_zpt_id, id_mandant, meteringcode, id_energieart, id_zp_typ,
            abnahmestelle_adresse, ablesetour_nr, wilken_brw_nr, wilken_zpt_ismesslokation,
            wilken_zpt_komplexemessung, created_at, changed_at,
            abnahmestelle_straße, abnahmestelle_hausnummer, abnahmestelle_hausnummer_zusatz,
            abnahmestelle_plz, abnahmestelle_ort,
            abnahmestelle_lat, abnahmestelle_lon, abnahmestelle_location_type,
            id_abn, id_netz, abnahmestelle_status,
            id_spannungsebene, id_spannungsebene_messung, anschlussleistung, installierte_leistung,
            gasdruck_mbar, id_lastprofil, id_zaehlverfahren,
            id_messstellenbetreiber, grundzustaendig_messstellenbetreiber
        )
        VALUES (
            s.id_zp, s.wilken_zpt_id, s.id_mandant, s.meteringcode, s.id_energieart, s.id_zp_typ,
            s.abnahmestelle_adresse, s.ablesetour_nr, s.wilken_brw_nr, s.wilken_zpt_ismesslokation,
            s.wilken_zpt_komplexemessung, s.created_at, s.changed_at,
            s.abnahmestelle_straße, s.abnahmestelle_hausnummer, s.abnahmestelle_hausnummer_zusatz,
            s.abnahmestelle_plz, s.abnahmestelle_ort,
            s.abnahmestelle_lat, s.abnahmestelle_lon, s.abnahmestelle_location_type,
            s.id_abn, s.id_netz, s.abnahmestelle_status,
            s.id_spannungsebene, s.id_spannungsebene_messung, s.anschlussleistung, s.installierte_leistung,
            s.gasdruck_mbar, s.id_lastprofil, s.id_zaehlverfahren,
            s.id_messstellenbetreiber, s.grundzustaendig_messstellenbetreiber
        );

    IF p_verbose = 1 THEN
        PERFORM util.log_detail(p_transform_job_id, c_sp, 'Ende');
    END IF;
END;
$$;
