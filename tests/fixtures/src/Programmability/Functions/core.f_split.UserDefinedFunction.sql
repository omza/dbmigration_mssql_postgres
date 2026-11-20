CREATE FUNCTION core.f_split ( @s VARCHAR(MAX) )
RETURNS @out TABLE (teil [nvarchar] (500))
AS
BEGIN
    DECLARE @pos INT
    WHILE CHARINDEX(',', @s) > 0
    BEGIN
        SELECT @pos = CHARINDEX(',', @s)
        INSERT INTO @out SELECT SUBSTRING(@s, 1, @pos - 1)
        SET @s = SUBSTRING(@s, @pos + 1, LEN(@s))
    END
    RETURN
END
GO
