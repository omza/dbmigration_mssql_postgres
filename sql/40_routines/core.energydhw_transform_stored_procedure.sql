-- Quelle: energydwh-main/Programmability/Stored Procedures/core.energydhw_transform_stored_procedure.StoredProcedure.sql
-- Talend:  exec core.energydhw_transform_stored_procedure 4711, N'[mart_dsai].[load_kunden_milieus]', 0
--     ->  SELECT * FROM core.energydhw_transform_stored_procedure(4711, '[mart_dsai].[load_kunden_milieus]', 0)
-- Ergebnis: (transform_job_id, transform_status, transform_message)
--   Im Original hieß die erste Spalte im Erfolgsfall transform_log_id, im Fehlerfall transform_job_id;
--   hier einheitlich transform_job_id (Talend liest positional).
-- Der SP-Name darf T-SQL-Schreibweise haben ([schema].[name]); er wird auf den PG-Namen abgebildet.
-- Konvention: Die aufgerufene Funktion hat die Signatur (bigint, integer). Fehler werden hier
-- protokolliert ('Abbruch DWH: <sp> ### <fehler>'), die Funktion selbst wird komplett zurückgerollt.
CREATE OR REPLACE FUNCTION core.energydhw_transform_stored_procedure(
    p_transform_job_id bigint,
    p_sp_transform     text,
    p_verbose          integer DEFAULT 0
)
RETURNS TABLE (transform_job_id bigint, transform_status integer, transform_message text)
LANGUAGE plpgsql
AS $$
#variable_conflict use_column
DECLARE
    v_sql     text;
    v_routine text;
    v_msg     text;
BEGIN
    BEGIN
        v_routine := util.routine_basename(p_sp_transform);
        v_sql := format('SELECT %s(%s, %s)', util.routine_name(p_sp_transform), p_transform_job_id, p_verbose);
        RAISE NOTICE '%', v_sql;
        EXECUTE v_sql;
    EXCEPTION WHEN OTHERS THEN
        v_msg := format('Abbruch DWH: %s ### %s', coalesce(v_routine, p_sp_transform), SQLERRM);
        PERFORM util.log_detail(p_transform_job_id, coalesce(v_routine, p_sp_transform), v_msg);
        RETURN QUERY SELECT p_transform_job_id, 2, v_msg;
        RETURN;
    END;

    RETURN QUERY SELECT p_transform_job_id, 1, 'Job wurde fehlerfrei ausgeführt'::text;
END;
$$;
