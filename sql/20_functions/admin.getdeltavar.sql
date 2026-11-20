-- Quelle: energydwh-main/Programmability/Functions/admin.getdeltavar.UserDefinedFunction.sql
-- Liefert alle {platzhalter} aus einer Deltabedingung, z.B. 'x > ''{changed_at}''' -> changed_at
-- Schleife 1:1 übernommen (inkl. T-SQL-LEN-Semantik), damit Grenzfälle identisch sind.
CREATE OR REPLACE FUNCTION admin.getdeltavar(stringtosplit text)
RETURNS TABLE (deltavar varchar(500))
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
    s    text := stringtosplit;
    name text;
    pos  integer;
    posa integer;
BEGIN
    WHILE strpos(s, '}') > 0 LOOP
        -- Ende kürzen
        pos  := strpos(s, '}');
        name := left(substring(s FROM 1 FOR pos - 1), 255);   -- @name NVARCHAR(255)
        -- Anfang kürzen
        posa := strpos(name, '{');
        name := substring(name FROM posa + 1 FOR util.len(name) - 1);
        deltavar := name;
        RETURN NEXT;
        s := substring(s FROM pos + 1 FOR util.len(s) - pos);
    END LOOP;
END;
$$;
