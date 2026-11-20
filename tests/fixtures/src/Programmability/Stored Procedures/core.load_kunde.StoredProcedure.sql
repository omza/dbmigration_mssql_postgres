CREATE PROCEDURE [core].[load_kunde]
    @job_id bigint,
    @verbose tinyint = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @n int = 0, @msg varchar(200);
    SELECT @msg = OBJECT_NAME(@@PROCID)

    BEGIN TRY
        UPDATE k SET aktiv = 0
        FROM core.kunde k JOIN core.gruppe g ON g.id_gruppe = k.id_gruppe
        WHERE g.bezeichnung IS NULL
        SET @n = @@ROWCOUNT
        IF @verbose = 1
            PRINT @msg + ': ' + CAST(@n AS varchar(10))
        ELSE IF @verbose = 2
        BEGIN
            SET @n += 1
        END
    END TRY
    BEGIN CATCH
        SET @msg = ERROR_MESSAGE();
        THROW 51000, @msg, 1;
    END CATCH
END
GO
