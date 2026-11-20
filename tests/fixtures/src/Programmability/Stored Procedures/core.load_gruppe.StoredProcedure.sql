CREATE PROCEDURE core.load_gruppe
AS
BEGIN
    WITH quelle AS (
        SELECT 1 AS id_gruppe, 'A' AS bezeichnung
    ), TargetRows AS (
        SELECT id_gruppe, bezeichnung, CHECKSUM(bezeichnung) AS cs
        FROM core.gruppe AS g
        WHERE g.id_gruppe > 0
    )
    MERGE INTO TargetRows AS Target
    USING (SELECT id_gruppe, bezeichnung, CHECKSUM(bezeichnung) AS cs FROM quelle) AS Source
    ON Source.id_gruppe = Target.id_gruppe
    WHEN MATCHED AND Source.cs <> Target.cs THEN
        UPDATE SET Target.bezeichnung = Source.bezeichnung
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (id_gruppe, bezeichnung) VALUES (Source.id_gruppe, Source.bezeichnung)
    WHEN NOT MATCHED BY SOURCE THEN
        DELETE;

    INSERT INTO core.kunde VALUES ('x', 1, '31.12.2099', GETDATE(), '')
    UPDATE core.kunde SET aktiv = 0 WHERE ISNULL(id_gruppe, '') = '' AND PATINDEX('%[0-9]%', name) > 0
END
GO
