-- Quelle: energydwh-main/Programmability/Stored Procedures/admin.start_load.StoredProcedure.sql
-- Talend:  exec admin.start_load 'full', 'SELECT * FROM CREATOR.ENMES', 'wilken_enmes'
--     ->  SELECT * FROM admin.start_load('full', 'SELECT * FROM CREATOR.ENMES', 'wilken_enmes')
-- Ergebnis: (load_id, src_query, load_type) – im Original war die erste Spalte unbenannt.
-- src_query ist eine Abfrage gegen das QUELLsystem (wird von Talend dort ausgeführt), nicht gegen PG.
CREATE OR REPLACE FUNCTION admin.start_load(
    p_load_type           varchar,
    p_src_query           text,
    p_dest_table          varchar,
    p_src_delta_condition text    DEFAULT '',
    p_dest_schema         varchar DEFAULT 'raw'
)
RETURNS TABLE (load_id bigint, src_query text, load_type varchar)
LANGUAGE plpgsql
AS $$
#variable_conflict use_column
DECLARE
    v_load_id  bigint;
    v_query    text;
    v_criteria text;
    v_maxdate  text;
BEGIN
    -- Starte Load log
    INSERT INTO admin.load_log (load_type, load_start_at, dest_table)
    VALUES (p_load_type, clock_timestamp(), p_dest_table)
    RETURNING admin.load_log.load_id INTO v_load_id;

    IF p_load_type = 'full' THEN
        UPDATE admin.load_log SET src_query = p_src_query WHERE load_id = v_load_id;

    ELSIF NOT util.table_exists(p_dest_schema, p_dest_table) THEN
        -- Initialload für Delta: Zieltabelle fehlt -> Full Load
        UPDATE admin.load_log
        SET src_query = p_src_query,
            load_type = 'delta_init'
        WHERE load_id = v_load_id;

    ELSE
        -- WHERE-Prüfung war case-insensitiv (CHARINDEX unter CI-Collation)
        IF strpos(upper(p_src_query), 'WHERE') > 0 THEN
            v_query := p_src_query || ' AND ' || p_src_delta_condition;
        ELSE
            v_query := p_src_query || ' WHERE ' || p_src_delta_condition;
        END IF;

        -- alle {platzhalter} durch das Maximum der gleichnamigen Spalte der Zieltabelle ersetzen
        FOR v_criteria IN SELECT deltavar FROM admin.getdeltavar(p_src_delta_condition) LOOP
            -- %s statt %I: Kriterium wird wie im Original als Ausdruck eingesetzt (unquotiert -> lowercase)
            EXECUTE format('SELECT util.style120(max(%s)) FROM %I.%I',
                           v_criteria, lower(p_dest_schema), lower(p_dest_table))
            INTO v_maxdate;
            v_maxdate := coalesce(v_maxdate, '1999-01-01');
            IF util.len(v_maxdate) = 10 THEN
                v_maxdate := v_maxdate || ' 00:00:00';
            END IF;
            v_query := replace(v_query, '{' || v_criteria || '}', v_maxdate);
        END LOOP;

        UPDATE admin.load_log SET src_query = v_query WHERE load_id = v_load_id;
    END IF;

    -- Output für den Talend Job
    RETURN QUERY
        SELECT l.load_id, l.src_query, l.load_type
        FROM admin.load_log l
        WHERE l.load_id = v_load_id;
END;
$$;
