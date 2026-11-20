-- Quelle: energydwh-main/Programmability/Stored Procedures/admin.start_transform.StoredProcedure.sql
-- Talend:  exec admin.start_transform                       (Standard)
--          exec admin.start_transform 0, '[mart_dsai].[load_kunden_milieus]'   (Einzel-SP)
--     ->  SELECT * FROM admin.start_transform()
--         SELECT * FROM admin.start_transform(0, '[mart_dsai].[load_kunden_milieus]')
-- Ergebnis: (transform_job_id, transform_message)
-- Abweichung: Debug-Ausgaben bei verbose > 0 kommen als NOTICE statt als zusätzliche Result-Sets.
CREATE OR REPLACE FUNCTION admin.start_transform(
    p_verbose      integer DEFAULT 0,
    p_sp_transform text    DEFAULT ''
)
RETURNS TABLE (transform_job_id bigint, transform_message text)
LANGUAGE plpgsql
AS $$
#variable_conflict use_column
DECLARE
    v_job_id bigint := -1;
    v_count  integer := 0;
    v_locked integer := 0;
    v_now    timestamp(3) := clock_timestamp();
BEGIN
    SELECT coalesce(max(t.transform_job_id), 0) + 1 INTO v_job_id FROM admin.transform_log t;
    IF p_verbose > 0 THEN
        RAISE NOTICE 'transform_job_id = %', v_job_id;
    END IF;

    IF coalesce(p_sp_transform, '') = '' THEN

        -- geänderte Quelltabellen dem Job zuordnen
        UPDATE admin.transform_log
        SET transform_job_id = v_job_id,
            transform_start_at = v_now
        WHERE transform_status = 0
          AND transform_job_id = -1;
        GET DIAGNOSTICS v_count = ROW_COUNT;

        IF v_count = 0 THEN
            RETURN QUERY SELECT -1::bigint, 'no need to run'::text;
            RETURN;
        END IF;

        -- unvollständige Loads abbrechen, wenn ein erfolgreicher Nachfolge-Load existiert
        -- (Tabellenvergleich war case-insensitiv -> lower())
        UPDATE admin.load_log l
        SET load_status = 2,
            load_end_at = v_now,
            load_message = coalesce(l.load_message, 'abgebrochen weil erfolgreicher nachfolger')
        FROM (
            SELECT x.load_id,
                   max(CASE WHEN x.load_status = 1 THEN x.load_start_at END)
                       OVER (PARTITION BY lower(x.dest_table)) AS max_start
            FROM admin.load_log x
            WHERE lower(x.dest_table) IN (
                SELECT lower(t.transform_source) FROM admin.transform_log t WHERE t.transform_job_id = v_job_id)
        ) m
        WHERE l.load_id = m.load_id
          AND l.load_start_at < coalesce(m.max_start, l.load_start_at)
          AND (l.load_end_at IS NULL OR l.load_status = 0);

        -- Trigger sperren, deren Rawtabelle gerade von einem anderen Job beladen wird
        UPDATE admin.transform_log t
        SET transform_message = 'locked'
        FROM admin.load_log l
        WHERE lower(t.transform_source) = lower(l.dest_table)
          AND l.load_status = 0
          AND t.transform_job_id = v_job_id;
        GET DIAGNOSTICS v_locked = ROW_COUNT;

        IF v_count > v_locked THEN
            INSERT INTO admin.transform_log
                (load_id, transform_job_id, transform_source, transform_triggered_at, transform_start_at, transform_status)
            VALUES (0, v_job_id, 'Job Kopfsatz (transform main)', v_now, v_now, 0);

            RETURN QUERY SELECT v_job_id, ''::text;
        ELSE
            -- alles gesperrt: Trigger zurücksetzen, nicht weiterlaufen
            UPDATE admin.transform_log
            SET transform_job_id = -1,
                transform_status = 0,
                transform_message = NULL
            WHERE transform_job_id = v_job_id
              AND load_id > 0
              AND transform_message = 'locked';

            RETURN QUERY SELECT -1::bigint, 'alle transformationen gesperrt'::text;
        END IF;

    ELSE
        -- Einzel-SP-Aufruf
        IF util.routine_exists(p_sp_transform) THEN
            INSERT INTO admin.transform_log
                (load_id, transform_job_id, transform_source, transform_triggered_at, transform_start_at, transform_status)
            VALUES (0, v_job_id, p_sp_transform || ' (transform sp)', v_now, v_now, 0);

            RETURN QUERY SELECT v_job_id, ''::text;
        ELSE
            RETURN QUERY SELECT -1::bigint, 'sp does not exist'::text;
        END IF;
    END IF;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -1::bigint, SQLERRM;
END;
$$;
