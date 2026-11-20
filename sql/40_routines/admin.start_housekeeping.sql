-- Quelle: energydwh-main/Programmability/Stored Procedures/admin.start_housekeeping.StoredProcedure.sql
-- Aufruf durch core.energydhw_transform_main (nicht direkt durch Talend).
-- Läuft höchstens einmal pro Tag. Fehler werden vom Aufrufer protokolliert (Konvention: Caller loggt).
CREATE OR REPLACE FUNCTION admin.start_housekeeping(p_transform_job_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    c_sp       CONSTANT text := 'start_housekeeping';
    c_max_tage CONSTANT integer := 90;
    v_last_run date;
BEGIN
    -- Ist das Housekeeping heute schon gelaufen?
    SELECT max(transform_timestamp)::date INTO v_last_run
    FROM admin.transform_log_detail
    WHERE transform_routine = c_sp;

    IF v_last_run IS NOT NULL AND v_last_run >= current_date THEN
        RETURN;
    END IF;

    PERFORM util.log_detail(p_transform_job_id, c_sp, 'Start');

    DELETE FROM admin.load_log
    WHERE load_start_at < current_date - c_max_tage;

    DELETE FROM admin.transform_log
    WHERE transform_job_id > 0
      AND transform_start_at < current_date - c_max_tage;

    DELETE FROM admin.transform_log_detail
    WHERE transform_timestamp < current_date - c_max_tage;

    -- offene Load-Logs schließen (läuft länger als einen Tag -> fehlerhaft)
    UPDATE admin.load_log
    SET load_status = 2,
        load_end_at = clock_timestamp(),
        load_message = coalesce(load_message, 'log durch housekeeping geschlossen')
    WHERE load_start_at::date <= current_date - 1
      AND (load_end_at IS NULL OR load_status = 0);

    PERFORM util.log_detail(p_transform_job_id, c_sp, 'Ende');
END;
$$;
