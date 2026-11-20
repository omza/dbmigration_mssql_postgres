-- Hilfsfunktionen, die T-SQL-Semantik nachbilden. Nur hier, damit Portierungen einheitlich sind.

-- ---------------------------------------------------------------------------------------------
-- util.len: T-SQL LEN() – Länge ohne Leerzeichen am Ende
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION util.len(s text)
RETURNS integer
LANGUAGE sql IMMUTABLE PARALLEL SAFE
RETURN length(rtrim(s, ' '));

-- ---------------------------------------------------------------------------------------------
-- util.datediff: T-SQL DATEDIFF(part, start, end) – zählt überschrittene Grenzen, nicht Intervalle.
--   DATEDIFF(year, '2024-12-31', '2025-01-01') = 1
--   week: Grenze ist der Sonntag (unabhängig von DATEFIRST, wie in T-SQL)
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION util.datediff(part text, startdate timestamp, enddate timestamp)
RETURNS bigint
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
AS $$
BEGIN
    IF startdate IS NULL OR enddate IS NULL THEN
        RETURN NULL;
    END IF;
    CASE lower(part)
        WHEN 'year', 'yy', 'yyyy' THEN
            RETURN extract(year FROM enddate) - extract(year FROM startdate);
        WHEN 'quarter', 'qq', 'q' THEN
            RETURN (extract(year FROM enddate) * 4 + extract(quarter FROM enddate))
                 - (extract(year FROM startdate) * 4 + extract(quarter FROM startdate));
        WHEN 'month', 'mm', 'm' THEN
            RETURN (extract(year FROM enddate) * 12 + extract(month FROM enddate))
                 - (extract(year FROM startdate) * 12 + extract(month FROM startdate));
        WHEN 'day', 'dd', 'd', 'dayofyear', 'dy', 'y' THEN
            RETURN enddate::date - startdate::date;
        WHEN 'week', 'wk', 'ww' THEN
            -- 1900-01-07 ist ein Sonntag
            RETURN floor((enddate::date - DATE '1900-01-07') / 7.0)
                 - floor((startdate::date - DATE '1900-01-07') / 7.0);
        WHEN 'hour', 'hh' THEN
            RETURN (extract(epoch FROM date_trunc('hour', enddate))
                  - extract(epoch FROM date_trunc('hour', startdate))) / 3600;
        WHEN 'minute', 'mi', 'n' THEN
            RETURN (extract(epoch FROM date_trunc('minute', enddate))
                  - extract(epoch FROM date_trunc('minute', startdate))) / 60;
        WHEN 'second', 'ss', 's' THEN
            RETURN extract(epoch FROM date_trunc('second', enddate))
                 - extract(epoch FROM date_trunc('second', startdate));
        WHEN 'millisecond', 'ms' THEN
            RETURN (extract(epoch FROM date_trunc('milliseconds', enddate))
                  - extract(epoch FROM date_trunc('milliseconds', startdate))) * 1000;
        ELSE
            RAISE EXCEPTION 'util.datediff: nicht unterstützter Datumsteil %', part;
    END CASE;
END;
$$;

-- ---------------------------------------------------------------------------------------------
-- util.try_decimal: T-SQL TRY_CAST(text AS decimal(p,s)). NULL statt Fehler bei ungültiger Eingabe
-- oder Überlauf. Wie T-SQL: keine Exponentialschreibweise, Leerzeichen außen erlaubt, rundet auf s.
-- Aufruf: util.try_decimal(x, 11, 8)::numeric(11,8)
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION util.try_decimal(v text, p integer, s integer)
RETURNS numeric
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
AS $$
BEGIN
    IF v IS NULL OR v !~ '^\s*[+-]?(\d+\.?\d*|\.\d+)\s*$' THEN
        RETURN NULL;
    END IF;
    IF NOT pg_input_is_valid(v, format('numeric(%s,%s)', p, s)) THEN
        RETURN NULL;
    END IF;
    RETURN round(btrim(v)::numeric, s);
END;
$$;

-- ---------------------------------------------------------------------------------------------
-- util.try_int / util.try_bigint: T-SQL TRY_CAST(text AS int/bigint)
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION util.try_int(v text)
RETURNS integer
LANGUAGE sql IMMUTABLE PARALLEL SAFE
RETURN CASE WHEN v ~ '^\s*[+-]?\d+\s*$' AND pg_input_is_valid(v, 'integer') THEN v::integer END;

CREATE OR REPLACE FUNCTION util.try_bigint(v text)
RETURNS bigint
LANGUAGE sql IMMUTABLE PARALLEL SAFE
RETURN CASE WHEN v ~ '^\s*[+-]?\d+\s*$' AND pg_input_is_valid(v, 'bigint') THEN v::bigint END;

-- ---------------------------------------------------------------------------------------------
-- util.style120: T-SQL CONVERT(varchar, x, 120) -> 'yyyy-mm-dd hh:mi:ss' (date: 'yyyy-mm-dd')
-- Für andere Typen (z.B. Integer-Deltakriterien) die Textdarstellung.
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION util.style120(v timestamp)
RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE
RETURN to_char(v, 'YYYY-MM-DD HH24:MI:SS');

CREATE OR REPLACE FUNCTION util.style120(v date)
RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE
RETURN to_char(v, 'YYYY-MM-DD');

CREATE OR REPLACE FUNCTION util.style120(v anyelement)
RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE
AS $$ SELECT v::text $$;

-- ---------------------------------------------------------------------------------------------
-- util.table_exists: T-SQL OBJECT_ID('schema.tabelle', 'U') IS NOT NULL
-- Case-insensitiv wie in MSSQL (Namen werden lowercase verglichen), nur Basistabellen.
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION util.table_exists(p_schema text, p_table text)
RETURNS boolean
LANGUAGE sql STABLE
RETURN EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind IN ('r', 'p')
      AND n.nspname = lower(btrim(p_schema, '[] '))
      AND c.relname = lower(btrim(p_table, '[] '))
);

-- ---------------------------------------------------------------------------------------------
-- util.routine_name: T-SQL-Prozedurname ('[core].[load_x]', 'core.load_x', 'CORE.Load_X')
--                    -> PG-Bezeichner 'core.load_x' (gequotet, falls nötig)
-- util.routine_basename: -> 'load_x' (entspricht OBJECT_NAME(@@PROCID) für Logeinträge)
-- util.routine_exists: T-SQL OBJECT_ID(name, 'P') IS NOT NULL
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION util.routine_name(p_name text)
RETURNS text
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
    parts text[];
BEGIN
    parts := string_to_array(replace(replace(lower(btrim(p_name)), '[', ''), ']', ''), '.');
    IF cardinality(parts) = 3 THEN          -- [EnergyDWH].[schema].[name]
        parts := parts[2:3];
    END IF;
    IF cardinality(parts) = 1 THEN
        parts := ARRAY['dbo', parts[1]];
    END IF;
    IF cardinality(parts) <> 2 THEN
        RAISE EXCEPTION 'Ungültiger Routinenname: %', p_name;
    END IF;
    RETURN quote_ident(parts[1]) || '.' || quote_ident(parts[2]);
END;
$$;

CREATE OR REPLACE FUNCTION util.routine_basename(p_name text)
RETURNS text
LANGUAGE sql IMMUTABLE
RETURN replace(split_part(util.routine_name(p_name), '.', 2), '"', '');

CREATE OR REPLACE FUNCTION util.routine_exists(p_name text)
RETURNS boolean
LANGUAGE sql STABLE
RETURN EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname || '.' || p.proname = replace(util.routine_name(p_name), '"', '')
);

-- ---------------------------------------------------------------------------------------------
-- util.log_detail: Eintrag in admin.transform_log_detail (für Start/Ende/Fehler)
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION util.log_detail(p_transform_job_id bigint, p_routine text, p_message text)
RETURNS void
LANGUAGE plpgsql   -- plpgsql: Rumpf wird erst zur Laufzeit gebunden (05_util läuft vor 10_tables)
AS $$
BEGIN
    INSERT INTO admin.transform_log_detail (transform_job_id, transform_routine, transform_message)
    VALUES (p_transform_job_id, p_routine, p_message);
END;
$$;

-- ---------------------------------------------------------------------------------------------
-- util.mssql_to_timestamp: implizite T-SQL-Konvertierung Text -> datetime für die im Bestand
-- vorkommenden Formate: ISO 'yyyy-mm-dd[ hh:mi[:ss[.fff]]]' und deutsch 'dd.mm.yyyy[ hh:mi[:ss]]'.
-- Andere Formate -> Fehler (wie in T-SQL). Timestamp-Eingaben werden durchgereicht.
-- ---------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION util.mssql_to_timestamp(v text)
RETURNS timestamp
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
AS $$
BEGIN
    IF v IS NULL THEN
        RETURN NULL;
    ELSIF v ~ '^\s*\d{4}-\d{2}-\d{2}' THEN
        RETURN btrim(v)::timestamp;
    ELSIF v ~ '^\s*\d{1,2}\.\d{1,2}\.\d{4}(\s+\d{1,2}:\d{2}(:\d{2})?)?\s*$' THEN
        RETURN to_timestamp(btrim(v), 'DD.MM.YYYY HH24:MI:SS')::timestamp;
    END IF;
    RAISE EXCEPTION 'Conversion failed when converting date and/or time from character string: %', v;
END;
$$;

CREATE OR REPLACE FUNCTION util.mssql_to_timestamp(v timestamp)
RETURNS timestamp LANGUAGE sql IMMUTABLE PARALLEL SAFE
RETURN v;
