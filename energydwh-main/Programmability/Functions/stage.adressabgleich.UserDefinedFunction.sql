-- Object: stage.adressabgleich
-- Type  : SQL_SCALAR_FUNCTION

CREATE FUNCTION [stage].[adressabgleich]
(
    @str_name VARCHAR(255),
    @hnr      VARCHAR(50),
    @hnr_zs   VARCHAR(50),
    @plz      VARCHAR(20),
    @po_name  VARCHAR(255)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE 
        @str         VARCHAR(MAX),
        @hnr_zs_clean VARCHAR(50),
        @po_clean    VARCHAR(255),
        @result_raw  VARCHAR(MAX),
        @result      VARCHAR(MAX),
        @i           INT,
        @len         INT,
        @ch          NCHAR(1),
        @allowed     NVARCHAR(200);

    --------------------------------------------------------------------
    -- 1) Straßenname normalisieren (entspricht dem großen REGEXP-Block)
    --------------------------------------------------------------------
    SET @str = LOWER(LTRIM(RTRIM(@str_name)));

    -- Ersetzungen wie in Postgres
    SET @str = REPLACE(@str, '-v-', '-von-');
    SET @str = REPLACE(@str, 'á', 'a');
    SET @str = REPLACE(@str, 'é', 'e');
    SET @str = REPLACE(@str, 'ä', 'ae');
    SET @str = REPLACE(@str, 'ö', 'oe');
    SET @str = REPLACE(@str, 'ü', 'ue');
    SET @str = REPLACE(@str, 'ß', 'ss');

    -- Leerzeichen entfernen (Regex [ ] -> '')
    SET @str = REPLACE(@str, ' ', '');

    -- (straße|strasse|str)\M -> 'straße'
    -- Approximiert: strasse/str. ersetzen, 'str' am Ende ersetzen
    SET @str = REPLACE(@str, 'strasse', 'straße');
    SET @str = REPLACE(@str, 'str.',    'straße');

    IF RIGHT(@str, 3) = 'str'
        SET @str = LEFT(@str, LEN(@str) - 3) + 'straße';

    --------------------------------------------------------------------
    -- 2) Hausnummer-Zusatz bereinigen: (haus|ahaus|hth|/)
    --------------------------------------------------------------------
    set @hnr_zs = isnull(@hnr,'') + isnull(@hnr_zs,'')
	
	SET @hnr_zs_clean = LOWER(LTRIM(RTRIM(@hnr_zs)));
    SET @hnr_zs_clean = REPLACE(@hnr_zs_clean, 'haus',  '');
    SET @hnr_zs_clean = REPLACE(@hnr_zs_clean, 'ahaus', '');
    SET @hnr_zs_clean = REPLACE(@hnr_zs_clean, 'hth',   '');
    SET @hnr_zs_clean = REPLACE(@hnr_zs_clean, '/',     '');
    SET @hnr_zs_clean = LTRIM(RTRIM(@hnr_zs_clean));

    --------------------------------------------------------------------
    -- 3) po_name bereinigen wie mit Regex '([,(](.*)|b\.(.*)|bei (.*))'
    --------------------------------------------------------------------
    DECLARE @s VARCHAR(255) = LOWER(LTRIM(RTRIM(@po_name)));
    DECLARE @pos INT;

    -- alles nach erstem Komma entfernen
    SET @pos = CHARINDEX(',', @s);
    IF @pos > 0
        SET @s = LEFT(@s, @pos - 1);

    -- alles nach erster Klammer '(' entfernen
    SET @pos = CHARINDEX('(', @s);
    IF @pos > 0
        SET @s = LEFT(@s, @pos - 1);

    -- alles ab 'b.' entfernen
    SET @pos = CHARINDEX('b.', @s);
    IF @pos > 0
        SET @s = LEFT(@s, @pos - 1);

    -- alles ab 'bei ' entfernen
    SET @pos = CHARINDEX('bei ', @s);
    IF @pos > 0
        SET @s = LEFT(@s, @pos - 1);

    SET @po_clean = LTRIM(RTRIM(@s));

    --------------------------------------------------------------------
    -- 4) Roh-String wie in Postgres CONCAT/CONCAT_WS bauen
    --------------------------------------------------------------------
    SET @result_raw =
          ISNULL(@str, '')
        + ';'
        --+ ISNULL(@hnr, '')
       -- + ';'
        + ISNULL(@hnr_zs_clean, '')
        + ';'
        + ISNULL(@plz, '')
        + ';'
        + ISNULL(@po_clean, '');

    --------------------------------------------------------------------
    -- 5) Final: alle anderen Sonderzeichen entfernen
    --     entspricht: REGEXP_REPLACE(..., '[^a-zäöüß0-9;]', '', 'g') [1]
    --------------------------------------------------------------------
    SET @allowed = N'abcdefghijklmnopqrstuvwxyz0123456789;äöüß';
    SET @result = '';
    SET @i = 1;
    SET @len = LEN(@result_raw);

    WHILE @i <= @len
    BEGIN
        SET @ch = SUBSTRING(@result_raw, @i, 1);

        -- In SQL Server 2014 gibt es keine Regex, wir prüfen per CHARINDEX:
        IF CHARINDEX(@ch, @allowed) > 0
        BEGIN
            SET @result = @result + @ch;
        END

        SET @i = @i + 1;
    END

    RETURN @result;
END;

GO
