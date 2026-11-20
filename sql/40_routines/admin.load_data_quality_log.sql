-- Quelle: energydwh-main/Programmability/Stored Procedures/admin.load_data_quality_log.StoredProcedure.sql
-- Talend:  exec admin.load_data_quality_log 'job', 'system', 'domain', 'objekt', 'mart_x.dq_view'
--     ->  SELECT * FROM admin.load_data_quality_log('job', 'system', 'domain', 'objekt', 'mart_x.dq_view')
-- p_src_query ist ein FROM-Ausdruck (Tabelle/View/Subquery mit Spalte "fehlerbild") und muss
-- PG-SQL sein -> Talend-Konfiguration prüfen (z.B. keine [eckigen Klammern]).
-- Abweichungen: Werte werden per quote_literal eingesetzt (statt String-Verkettung); im Fehlerfall
-- gibt es nur den Fehler (T-SQL lieferte zusätzlich vorher ein Result-Set mit derselben Meldung).
CREATE OR REPLACE FUNCTION admin.load_data_quality_log(
    p_dqm_job   varchar,
    p_system    varchar,
    p_domain    varchar,
    p_object    varchar,
    p_src_query text
)
RETURNS TABLE (message text)
LANGUAGE plpgsql
AS $$
#variable_conflict use_column
BEGIN
    BEGIN
        EXECUTE format($sql$
            MERGE INTO admin.data_quality_log AS target
            USING (
                SELECT %L::varchar AS dqm_job,
                       %L::varchar AS system,
                       %L::varchar AS domain,
                       %L::varchar AS object,
                       fehlerbild AS failure,
                       count(*) AS count_rows,
                       current_date AS datum
                FROM %s
                GROUP BY fehlerbild
            ) AS src
            ON  target.system = src.system
            AND target.domain = src.domain
            AND target.object = src.object
            AND target.failure = src.failure
            AND target.datum = src.datum
            WHEN MATCHED THEN
                UPDATE SET dqm_job = src.dqm_job,
                           count_rows = src.count_rows
            WHEN NOT MATCHED THEN
                INSERT (dqm_job, system, domain, object, failure, count_rows, datum)
                VALUES (src.dqm_job, src.system, src.domain, src.object, src.failure, src.count_rows, src.datum)
            $sql$, p_dqm_job, p_system, p_domain, p_object, p_src_query);
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Fehlerbild Spalte nicht gefunden, keine Datenqualitätsergebnisse gespeichert.'
            USING ERRCODE = 'P0001', DETAIL = SQLERRM;
    END;

    RETURN QUERY SELECT 'Datenqualitätsergebnisse gespeichert'::text;
END;
$$;
