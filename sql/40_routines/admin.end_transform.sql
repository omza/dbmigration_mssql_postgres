-- Quelle: energydwh-main/Programmability/Stored Procedures/admin.end_transform.StoredProcedure.sql
-- Talend:  exec admin.end_transform 4711, 1, 'ok'
--     ->  SELECT * FROM admin.end_transform(4711, 1, 'ok')
-- Ergebnis: im Erfolgsfall keine Zeile, im Fehlerfall (transform_job_id, transform_message) – wie im Original.
CREATE OR REPLACE FUNCTION admin.end_transform(
    p_transform_job_id  bigint,
    p_transform_status  integer,
    p_transform_message text
)
RETURNS TABLE (transform_job_id bigint, transform_message text)
LANGUAGE plpgsql
AS $$
#variable_conflict use_column
DECLARE
    v_end_at timestamp(3) := clock_timestamp();
BEGIN
    IF p_transform_job_id > 0 THEN

        -- Status auf alle Positionen
        UPDATE admin.transform_log
        SET transform_end_at = v_end_at,
            transform_status = p_transform_status
        WHERE transform_job_id = p_transform_job_id;

        -- Message auf den Kopfsatz
        UPDATE admin.transform_log
        SET transform_message = btrim(left(p_transform_message, 500), ' ')
        WHERE transform_job_id = p_transform_job_id
          AND load_id = 0;

        -- gesperrte Trigger zurücksetzen
        UPDATE admin.transform_log
        SET transform_job_id = -1,
            transform_status = 0,
            transform_message = NULL
        WHERE transform_job_id = p_transform_job_id
          AND load_id > 0
          AND transform_message = 'locked';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT p_transform_job_id, SQLERRM;
END;
$$;
