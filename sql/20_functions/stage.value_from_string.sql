-- Quellen: energydwh-main/Programmability/Functions/stage.numeric_value_from_string.UserDefinedFunction.sql
--          energydwh-main/Programmability/Functions/stage.alphanumeric_value_from_string.UserDefinedFunction.sql

-- Ziffernklasse: Unter Latin1_General_CI_AS matcht LIKE/PATINDEX '[0-9]' auch ²³¹¼½¾
-- (ermittelt per Abfrage gegen SQL Server, siehe tests/test_functions_diff.py).

-- Entfernt alle Nicht-Ziffern. NULL -> '0' (ISNULL(@inputString, 0) im Original).
-- Eingabe war VARCHAR(256) -> wird wie in T-SQL auf 256 Zeichen gekürzt.
CREATE OR REPLACE FUNCTION stage.numeric_value_from_string(inputstring text)
RETURNS varchar(256)
LANGUAGE sql IMMUTABLE PARALLEL SAFE
RETURN coalesce(regexp_replace(left(inputstring, 256), '[^0-9²³¹¼½¾]', '', 'g'), '0');

-- Entfernt alle Ziffern. NULL -> '' (Schleife läuft im Original bei NULL nicht, Ergebnis bleibt '').
-- LEN() ignoriert Leerzeichen am Ende -> die werden im Original nie übernommen.
CREATE OR REPLACE FUNCTION stage.alphanumeric_value_from_string(input text)
RETURNS text
LANGUAGE sql IMMUTABLE PARALLEL SAFE
RETURN coalesce(regexp_replace(rtrim(input, ' '), '[0-9²³¹¼½¾]', '', 'g'), '');
