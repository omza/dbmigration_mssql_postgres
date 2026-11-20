-- Quelle: energydwh-main/Programmability/Stored Procedures/core.energydhw_transform_main.StoredProcedure.sql
-- Talend:  exec core.energydhw_transform_main 4711
--     ->  SELECT * FROM core.energydhw_transform_main(4711)
-- Ergebnis: (transform_job_id, transform_status, transform_message); Status 1 = ok, 2 = Fehler.
--
-- Portierung:
--   * Die 34 Kontextblöcke des Originals stehen als Tabelle `steps` (maschinell aus dem Original
--     extrahiert, Reihenfolge identisch). Ein Block läuft, wenn mindestens eine seiner Quelltabellen
--     im Job getriggert und keine davon gesperrt ist.
--   * Jeder Aufruf läuft in einer eigenen Subtransaktion: Schlägt er fehl, wird nur er zurückgerollt,
--     der Fehler in admin.transform_log_detail protokolliert ('Abbruch DWH: <sp> ### <fehler>') und
--     der Job mit Status 2 beendet. Vorher erfolgreiche Aufrufe bleiben erhalten (wie in MSSQL).
--   * Kontextvergleich war case-insensitiv -> lower().
--   * Housekeeping lief im Original nach dem Status-Result-Set; Talend sah daher auch bei einem
--     Housekeeping-Fehler Status 1. Hier: Fehler wird protokolliert, Status bleibt 1.
--   * BEKANNTE EIGENHEITEN des Originals (bewusst übernommen, bitte fachlich prüfen):
--       Block 28: Kontext '[raw].[wilken_enzptgeraet]' trifft nie (Talend schreibt 'wilken_enzptgeraet')
--       Block 31: 'wilken_wilken_ensvba', 'wilken_wilken_edwaen' treffen nie (doppeltes Präfix)
CREATE OR REPLACE FUNCTION core.energydhw_transform_main(p_transform_job_id bigint)
RETURNS TABLE (transform_job_id bigint, transform_status integer, transform_message text)
LANGUAGE plpgsql
AS $$
#variable_conflict use_column
DECLARE
    c_verbose CONSTANT integer := 1;   -- globale Einstellung für Logging in admin.transform_log_detail
    v_sources text[];
    v_locked  text[];
    v_count   integer := 0;
    v_step    record;
    v_call    text;
    v_routine text;
    v_msg     text;
BEGIN
    -- Muss die Job-ID ausgeführt werden?
    SELECT coalesce(array_agg(lower(t.transform_source)), '{}'),
           coalesce(array_agg(lower(t.transform_source)) FILTER (WHERE t.transform_message = 'locked'), '{}')
    INTO v_sources, v_locked
    FROM admin.transform_log t
    WHERE t.transform_job_id = p_transform_job_id
      AND t.transform_status = 0;

    IF cardinality(v_sources) = 0 THEN
        RETURN QUERY SELECT p_transform_job_id, 1,
            'Job wurde bereits durchgeführt oder kein Kontext gefunden'::text;
        RETURN;
    END IF;

    FOR v_step IN
        SELECT s.ord, s.contexts, s.calls
        FROM (VALUES
            ( 1, ARRAY['wilken_enmnd'],
                 ARRAY['core.load_mandant(%1$s)']),
            ( 2, ARRAY['wilken_crena'],
                 ARRAY['core.load_energiearten(%1$s)']),
            ( 3, ARRAY['wilken_enlastprofil'],
                 ARRAY['core.load_lastprofile(%1$s)']),
            ( 4, ARRAY['wilken_edprggrundlage'],
                 ARRAY['core.load_prognosegrundlage(%1$s)']),
            ( 5, ARRAY['wilken_enzaehlverfahren'],
                 ARRAY['core.load_zaehlverfahren(%1$s)']),
            ( 6, ARRAY['wilken_enmessstellenbetreiber'],
                 ARRAY['core.load_messtellenbetreiber(%1$s)']),
            ( 7, ARRAY['wilken_ennet'],
                 ARRAY['core.load_netze(%1$s)']),
            ( 8, ARRAY['wilken_enobis'],
                 ARRAY['core.load_obis(%1$s)']),
            ( 9, ARRAY['wilken_enkng'],
                 ARRAY['core.load_kundengruppen(%1$s)']),
            (10, ARRAY['wilken_enkategorie'],
                 ARRAY['core.load_kundenkategorie(%1$s)']),
            (11, ARRAY['wilken_crprodukt', 'wilken_crproduktvarianten'],
                 ARRAY['core.load_produkte(%1$s)']),
            (12, ARRAY['wilken_crgpvertrag', 'wilken_crgpvertraglink'],
                 ARRAY['core.load_vertraege(%1$s)', 'core.load_link_kunde_zaehlpunkt(%1$s, %2$s)']),
            (13, ARRAY['wilken_g4bm_gsprolle', 'wilken_g4bm_gspartner', 'wilken_g4bm_gspkmwadrvwnd', 'wilken_g4bm_gspadresse', 'wilken_enknd', 'wilken_g4bm_gspadrzeit', 'wilken_g4bm_gspersart', 'wilken_g4bm_gspperson', 'wilken_g4bm_anrede', 'wilken_g4bm_titel'],
                 ARRAY['core.load_kunden(%1$s, %2$s)']),
            (14, ARRAY['wilken_enspannungsebene'],
                 ARRAY['core.load_spannungsebenen(%1$s, %2$s)']),
            (15, ARRAY['wilken_enabn', 'wilken_enzpt', 'wilken_enmes', 'wilken_enzmk', 'address_geolocation', 'wilken_enzpn'],
                 ARRAY['core.load_zaehlpunkte(%1$s, %2$s)', 'core.load_link_kunde_zaehlpunkt(%1$s, %2$s)', 'core.load_fallgruppen(%1$s, %2$s)']),
            (16, ARRAY['wilken_enzptmlk', 'wilken_enmlk'],
                 ARRAY['core.load_marktlokationen(%1$s, %2$s)']),
            (17, ARRAY['wilken_enlieferant'],
                 ARRAY['core.load_lieferanten(%1$s, %2$s)']),
            (18, ARRAY['wilken_enzaehlertyp'],
                 ARRAY['core.load_geraetetypen(%1$s)']),
            (19, ARRAY['wilken_ensztp'],
                 ARRAY['core.load_standard_geraetetypen(%1$s, %2$s)']),
            (20, ARRAY['wilken_enzaehlerlos', 'wilken_enzaehler', 'wilken_enzenr', 'wilken_enzpgd', 'wilken_enzptgeraet'],
                 ARRAY['core.load_geraete(%1$s, %2$s)', 'core.load_link_zaehlpunkt_geraet(%1$s, %2$s)']),
            (21, ARRAY['argos_lastgang'],
                 ARRAY['core.load_argos_lastgang(%1$s)', 'core.load_wertstatus(%1$s)', 'core.load_argos_messpunkte_und_werte(%1$s)']),
            (22, ARRAY['nedi_devices', 'nedi_interfaces', 'nedi_inventory', 'nedi_modules'],
                 ARRAY['core.load_geraetetypen_powerswitch(%1$s)', 'core.load_messpunkte_powerswitch_sagamfg(%1$s)', 'core.load_messpunkte_powerswitch_sagaipuep(%1$s)', 'core.load_messwerte_powerswitch_sagaipuep(%1$s)']),
            (23, ARRAY['power_switch_power_eltek_saga'],
                 ARRAY['core.load_messwerte_powerswitch_sagamfg(%1$s)']),
            (24, ARRAY['dezem_rz21_swn'],
                 ARRAY['core.load_dezem_messpunkte_und_werte(%1$s, ''dezem_rz21_swn'', 0)']),
            (25, ARRAY['dezem_rz21_wtg'],
                 ARRAY['core.load_dezem_messpunkte_und_werte(%1$s, ''dezem_rz21_wtg'', 0)']),
            (26, ARRAY['element_iot_devices'],
                 ARRAY['core.load_messpunkte_elementiot_stromzaehler(%1$s)', 'core.load_messpunkte_elementiot_waermezaehler(%1$s)', 'core.load_messpunkte_elementiot_wasserzaehler(%1$s)']),
            (27, ARRAY['wilken_enzpzstand'],
                 ARRAY['mart_dsai.load_ablesekarten(%1$s)']),
            (28, ARRAY['wilken_engeraetebeziehung', 'wilken_engeraetebeziehungdef', '[raw].[wilken_enzptgeraet]'],
                 ARRAY['core.load_link_geraetebeziehungen(%1$s)']),
            (29, ARRAY['wilken_enlauftour'],
                 ARRAY['core.load_ablesetouren(%1$s)']),
            (30, ARRAY['wilken_enlokbuendelzeit', 'wilken_enlokbuendelelement', 'wilken_enlokationsbuendelstruktur', 'wilken_enlokationsbuendel', 'wilken_enlokstrukturobjekt'],
                 ARRAY['core.load_lokationsbuendel(%1$s)']),
            (31, ARRAY['wilken_entremarktlokation', 'wilken_entechnischeressource', 'wilken_entredaten', 'wilken_wilken_ensvba', 'wilken_wilken_edwaen', 'wilken_entremesslokation'],
                 ARRAY['core.load_technische_ressourcen(%1$s)']),
            (32, ARRAY['wilken_enespnetzverknuepfungspunkt', 'wilken_enespanlnvp', 'wilken_enespzptanlage', 'wilken_enespanlstromerzeugungseinheit', 'wilken_enespanlage', 'wilken_enespenergietraeger'],
                 ARRAY['core.load_einspeiseanlagen(%1$s)']),
            (33, ARRAY['wilken_enzptem', 'wilken_enzptma'],
                 ARRAY['core.load_zaehlpunkt_jahresverbraeuche_abgerechnet(%1$s)']),
            (34, ARRAY['wilken_enzpbdaten'],
                 ARRAY['core.load_zaehlpunkt_bilanzierungsdaten(%1$s)'])

        ) AS s(ord, contexts, calls)
        ORDER BY s.ord
    LOOP
        CONTINUE WHEN NOT (v_sources && v_step.contexts) OR (v_locked && v_step.contexts);

        FOREACH v_call IN ARRAY v_step.calls LOOP
            v_routine := split_part(split_part(v_call, '(', 1), '.', 2);
            BEGIN
                EXECUTE 'SELECT ' || format(v_call, p_transform_job_id, c_verbose);
            EXCEPTION WHEN OTHERS THEN
                v_msg := format('Abbruch DWH: %s ### %s', v_routine, SQLERRM);
                PERFORM util.log_detail(p_transform_job_id, v_routine, v_msg);
                RETURN QUERY SELECT p_transform_job_id, 2, v_msg;
                RETURN;
            END;
            v_count := v_count + 1;
        END LOOP;
    END LOOP;

    -- Housekeeping (Fehler protokollieren, Status bleibt 1 – siehe Kopf)
    BEGIN
        PERFORM admin.start_housekeeping(p_transform_job_id);
    EXCEPTION WHEN OTHERS THEN
        PERFORM util.log_detail(p_transform_job_id, 'start_housekeeping',
                                format('Abbruch DWH: start_housekeeping ### %s', SQLERRM));
    END;

    RETURN QUERY SELECT p_transform_job_id, 1,
        v_count || ' Subprozeduren aufgerufen. Transformationsjob abgeschlossen';
END;
$$;
