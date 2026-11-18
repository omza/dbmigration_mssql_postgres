-- Object: core.load_geraetetypen_powerswitch
-- Type  : SQL_STORED_PROCEDURE

/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.geraetetypen
	

-- Change Log

	26.03.2025	OME initial



-- Test:

	exec core.load_geraetetypen_powerswitch -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].load_geraetetypen_powerswitch
	@transform_job_id bigint,
	@verbose tinyint = 0
AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Get SP Name
	DECLARE @SP_NAME varchar(100);
	SELECT @SP_NAME = OBJECT_NAME(@@PROCID);

	IF @verbose = 1 -- Exec Log Detail with SP Name
		INSERT INTO [admin].[transform_log_detail] ([transform_job_id],[transform_routine],[transform_message])
		VALUES (@transform_job_id, @SP_NAME, 'Start')
	

	BEGIN TRY
	--	---------------------------------------------------

	/*
		Verarbeiten Zählertypen aus powerswitch
	*/
	WITH TargetRows AS 
	(
		----- ZIEL -----
		SELECT 
			[id_mandant]
			,[id_energieart]
			,[id_quellsystem]
			,[geraetetyp]
			,[quellsystem_ident]
			,[quellsystem_status]
			,changed_at
			,CHECKSUM(
				[id_mandant]
				,[id_energieart]
				,[geraetetyp]
				,[quellsystem_status]
			) AS [CHECKSUM]
		FROM 
			[core].[geraetetypen] AS	Dim
		WHERE
			id_quellsystem = 3

	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		SELECT DISTINCT
			2 [id_mandant]
			,1 [id_energieart]
			,3 [id_quellsystem]
			,pwrswitch_types.type as [geraetetyp]
			,pwrswitch_types.type as [quellsystem_ident]
			,1 [quellsystem_status]
			,CHECKSUM (2, 1, pwrswitch_types.type, 1) as [CHECKSUM]
		FROM 
	
		(SELECT type FROM [raw].[power_switch_list_eltek_saga]
			UNION 
		SELECT type FROM [raw].[power_switch_list_ipuep_saga]) pwrswitch_types


		----- QUELLE -----
	)
	AS Source	ON		Source.[quellsystem_ident] = Target.[quellsystem_ident] and Source.[id_quellsystem] = Target.[id_quellsystem]

	WHEN MATCHED AND Source.[CHECKSUM] != Target.[CHECKSUM] THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 

					Target.[id_mandant] = Source.[id_mandant]
					,Target.[id_energieart] =  Source.[id_energieart]
					,Target.[geraetetyp] = Source.[geraetetyp]
					,Target.[quellsystem_status] = Source.[quellsystem_status]
					,Target.changed_at	=	GETDATE()
				

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_mandant]
			,[id_energieart]
			,[id_quellsystem]
			,[geraetetyp]
			,[quellsystem_ident]
			,[quellsystem_status]
		)
		VALUES (
			Source.[id_mandant]
			,Source.[id_energieart]
			,Source.[id_quellsystem]
			,Source.[geraetetyp]
			,Source.[quellsystem_ident]
			,Source.[quellsystem_status]

		);
		


	--	---------------------------------------------------
	--	---------------------------------------------------
	END TRY
	--	---------------------------------------------------
	BEGIN CATCH
		-- Fehlermeldung zusammenbauen
		DECLARE @Message varchar(MAX) = CONCAT('Abbruch DWH: ', @SP_NAME, ' ### ',  ERROR_MESSAGE());

		-- Fehlermeldung ins Job Log Detail schreiben
		INSERT INTO [admin].[transform_log_detail] ([transform_job_id],[transform_routine],[transform_message])
		VALUES (@transform_job_id, @SP_NAME, @Message);

		-- Hier noch den Fehler eskalieren, damit abgebrochen wird
		THROW 51111, @Message, 1;

	END CATCH;

	--	---------------------------------------------------
	IF @verbose = 1 -- Exec Log Detail with SP Name
		INSERT INTO [admin].[transform_log_detail] ([transform_job_id],[transform_routine],[transform_message])
		VALUES (@transform_job_id, @SP_NAME, 'Ende')


END;

GO
