-- Quelle: energydwh-main/Programmability/Functions/stage.json_value_from_key.UserDefinedFunction.sql
-- Primitive "JSON"-Suche wie im Original (Split an Komma, erstes Element, das den Schlüssel enthält).
-- Unterschiede: LIKE war case-insensitiv -> ILIKE; TOP 1 ohne ORDER BY -> erstes Element (number).
CREATE OR REPLACE FUNCTION stage.json_value_from_key(p_json text, p_key text)
RETURNS text
LANGUAGE plpgsql STABLE
AS $$
DECLARE
    v_item text;
BEGIN
    SELECT s.item INTO v_item
    FROM stage.splitstrings(p_json, ',') s
    WHERE s.item ILIKE '%' || p_key || '%'
    ORDER BY s.number
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    RETURN replace(replace(replace(replace(replace(
               right(v_item, util.len(v_item) - strpos(v_item, ':')),
           ' ', ''), '''', ''), '}', ''), '{', ''), '"', '');
END;
$$;
