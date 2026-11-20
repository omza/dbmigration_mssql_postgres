-- Quelle: energydwh-main/Programmability/Stored Procedures/admin.load_load_freshness.StoredProcedure.sql
-- Talend:  exec admin.load_load_freshness
--     ->  SELECT * FROM admin.load_load_freshness()
-- Ergebnis: nicht "frische" Tabellen (dest_table, max_load_at, last_load_id, last_load_at,
--           last_load_status, max_days_age)
-- Portierung:
--   * sys.tables/sys.columns -> pg_class/pg_attribute (Basistabellen im Schema raw mit Spalte load_at)
--   * LEAD(load_start_at, 1, 0): T-SQL-Default 0 = 1900-01-01 -> erster Load liefert ~45.000 Tage
--     (wird so übernommen; wirkt nur beim INSERT neuer Tabellen)
--   * DATEDIFF(day, a, b) = b::date - a::date
--   * Tabellennamen-Join war case-insensitiv -> lower()
--   * raw.sharepoint_saganetzaufbau_mfg_uebersicht.load_at ist varchar(20): T-SQL nahm MAX() über Text
--     und konvertierte implizit (abhängig von der Login-Sprache). Hier util.mssql_to_timestamp
--     (ISO oder dd.mm.yyyy). FACHLICH PRÜFEN: Format der echten Werte.
CREATE OR REPLACE FUNCTION admin.load_load_freshness()
RETURNS TABLE (
    dest_table       varchar(128),
    max_load_at      timestamp(3),
    last_load_id     bigint,
    last_load_at     timestamp(3),
    last_load_status smallint,
    max_days_age     integer
)
LANGUAGE plpgsql
AS $$
#variable_conflict use_column
DECLARE
    r record;
BEGIN
    WITH rawtables AS (
        SELECT n.nspname::varchar(128) AS schema,
               c.relname::varchar(128) AS dest_table
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = 'load_at' AND NOT a.attisdropped
        WHERE c.relkind IN ('r', 'p')
          AND n.nspname = 'raw'
    ), loads AS (
        SELECT l.dest_table,
               l.load_id AS last_load_id,
               l.load_start_at AS last_load_at,
               l.load_status AS last_load_status,
               row_number() OVER (PARTITION BY lower(l.dest_table) ORDER BY l.load_start_at DESC NULLS LAST) AS rang,
               l.load_start_at::date
                 - (lead(l.load_start_at, 1, TIMESTAMP '1900-01-01')
                       OVER (PARTITION BY lower(l.dest_table) ORDER BY l.load_start_at DESC NULLS LAST))::date
                 AS days_to_previous
        FROM admin.load_log l
    )
    MERGE INTO admin.load_freshness AS target
    USING (
        SELECT r.schema,
               r.dest_table,
               NULL::timestamp(3) AS max_load_at,
               l.last_load_id,
               l.last_load_at,
               l.last_load_status,
               CASE WHEN coalesce(l.days_to_previous, 0) = 0 THEN 1 ELSE l.days_to_previous END AS max_days_age,
               0 AS freshness_ignore
        FROM rawtables r
        LEFT JOIN loads l ON lower(r.dest_table) = lower(l.dest_table) AND l.rang = 1
    ) AS source
    ON source.dest_table = target.dest_table
    WHEN MATCHED THEN
        UPDATE SET last_load_id = source.last_load_id,
                   last_load_at = source.last_load_at,
                   last_load_status = source.last_load_status,
                   changed_at = clock_timestamp()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (schema, dest_table, max_load_at, last_load_id, last_load_at, last_load_status, max_days_age, freshness_ignore)
        VALUES (source.schema, source.dest_table, source.max_load_at, source.last_load_id, source.last_load_at,
                source.last_load_status, source.max_days_age, source.freshness_ignore)
    WHEN NOT MATCHED BY SOURCE THEN
        DELETE;

    -- max(load_at) je Zieltabelle
    FOR r IN SELECT f.schema, f.dest_table FROM admin.load_freshness f LOOP
        EXECUTE format(
            'UPDATE admin.load_freshness SET max_load_at = '
            '(SELECT coalesce(util.mssql_to_timestamp(max(load_at)), TIMESTAMP ''1900-01-01'') FROM %I.%I) '
            'WHERE dest_table = %L',
            r.schema, r.dest_table, r.dest_table);
    END LOOP;

    -- nicht "frische" Tabellen
    RETURN QUERY
        SELECT f.dest_table, f.max_load_at, f.last_load_id, f.last_load_at, f.last_load_status, f.max_days_age
        FROM admin.load_freshness f
        WHERE f.freshness_ignore = 0
          AND (f.last_load_status <> 1
               OR (CASE WHEN f.last_load_at > f.max_load_at THEN f.last_load_at ELSE f.max_load_at END)
                    + make_interval(days => f.max_days_age) < localtimestamp);

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Abbruch DWH: load_load_freshness ### %', SQLERRM;
END;
$$;
