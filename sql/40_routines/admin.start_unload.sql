-- Quelle: energydwh-main/Programmability/Stored Procedures/admin.start_unload.StoredProcedure.sql
-- Talend:  exec admin.start_unload 'job', 'SELECT ...', 'ziel', 'empfaenger'
--     ->  SELECT * FROM admin.start_unload('job', 'SELECT ...', 'ziel', 'empfaenger')
-- Hinweis: src_query wird von Talend gegen dieses DWH ausgeführt -> muss PG-SQL sein (Talend-Konfiguration prüfen).
CREATE OR REPLACE FUNCTION admin.start_unload(
    p_unload_job  varchar,
    p_src_query   text,
    p_destination varchar,
    p_receipents  varchar DEFAULT ''
)
RETURNS TABLE (unload_id bigint, src_query text)
LANGUAGE plpgsql
AS $$
#variable_conflict use_column
DECLARE
    v_unload_id bigint;
BEGIN
    INSERT INTO admin.unload_log (unload_job, unload_start_at, src_query, destination, recipient)
    VALUES (p_unload_job, clock_timestamp(), p_src_query, p_destination, p_receipents)
    RETURNING admin.unload_log.unload_id INTO v_unload_id;

    RETURN QUERY
        SELECT u.unload_id, u.src_query
        FROM admin.unload_log u
        WHERE u.unload_id = v_unload_id;
END;
$$;
