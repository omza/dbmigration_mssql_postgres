-- Quelle: energydwh-main/Programmability/Functions/stage.SplitStrings.UserDefinedFunction.sql
-- Ersetzt auch RealDWH.dbo.SplitStrings (gleiche Logik).
-- T-SQL-Verhalten:
--   * Elemente werden links/rechts von Leerzeichen befreit, leere Elemente bleiben erhalten
--   * Elemente, die hinter LEN(@List) beginnen, entfallen (=> leeres Element nach abschließendem
--     Trennzeichen fällt weg: 'a,b,' -> a, b)
--   * NULL oder '' -> keine Zeilen
--   * Ausgelegt auf einstellige Trennzeichen (wie das Original)
CREATE OR REPLACE FUNCTION stage.splitstrings(list text, delimiter text)
RETURNS TABLE (number bigint, item text)
LANGUAGE sql IMMUTABLE PARALLEL SAFE
AS $$
    SELECT row_number() OVER (ORDER BY ord) AS number,
           btrim(part, ' ')                 AS item
    FROM (
        SELECT part,
               ord,
               sum(length(part) + length(delimiter)) OVER (ORDER BY ord) - length(part) - length(delimiter) + 1 AS startpos
        FROM string_to_table(list, delimiter) WITH ORDINALITY AS t(part, ord)
    ) x
    WHERE startpos <= length(rtrim(list, ' '))
    ORDER BY ord
$$;
