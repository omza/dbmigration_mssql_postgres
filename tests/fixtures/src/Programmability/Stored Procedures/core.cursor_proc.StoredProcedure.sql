CREATE PROCEDURE core.cursor_proc AS
BEGIN
    DECLARE c CURSOR FOR SELECT id_kunde FROM core.kunde
    OPEN c
END
GO
