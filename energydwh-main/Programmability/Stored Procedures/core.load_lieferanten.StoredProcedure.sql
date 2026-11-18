-- Object: core.load_lieferanten
-- Type  : SQL_STORED_PROCEDURE

/* =============================================
-- Author:		Oliver Meyer
-- Create date: 30.06.2025
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.lieferanten 
	

-- Change Log

	30.06.2025	OME initial
	


-- Test:

	exec core.load_lieferanten -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_lieferanten]
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

	WITH TargetRows AS 
	(
		----- ZIEL -----
		SELECT  
			[id_lieferant]
			,[id_mandant]
			,[id_energieart]
			,[lieferant]
			,[lieferant_kurz]
			,[eic_nummer]
			,[id_kunde]
			,[flag_aktiv]
			,created_at
			,changed_at
			,CHECKSUM(
				[id_mandant]
				,[id_energieart]
				,[lieferant]
				,[lieferant_kurz]
				,[eic_nummer]
				,[id_kunde]
				,[flag_aktiv]
				,created_at
				,changed_at
			) AS CHECKSUM
		  FROM [core].lieferanten	AS	Dim


	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		SELECT  
			[id_lieferant]
			,[id_mandant]
			,[id_energieart]
			,[lieferant]
			,[lieferant_kurz]
			,[eic_nummer]
			,[id_kunde]
			,[flag_aktiv]
			,created_at
			,changed_at			
			,CHECKSUM(
				[id_mandant]
				,[id_energieart]
				,[lieferant]
				,[lieferant_kurz]
				,[eic_nummer]
				,[id_kunde]
				,[flag_aktiv]
				,created_at
				,changed_at
			) AS CHECKSUM
		FROM 
			[stage].[wilken_lieferanten]
		----- QUELLE -----
	)
	AS Source	ON		Source.[id_lieferant] = Target.[id_lieferant]

	WHEN MATCHED AND Source.[CHECKSUM] != Target.[CHECKSUM] THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					Target.[id_mandant]							=	Source.[id_mandant]
				,	Target.[id_energieart]				=	Source.[id_energieart]
				,	Target.[lieferant]					=	Source.[lieferant]
				,	Target.[lieferant_kurz]					=	Source.[lieferant_kurz]

				,	Target.[eic_nummer]					=	Source.[eic_nummer]
				,	Target.[id_kunde]				=	Source.[id_kunde]
				,	Target.[flag_aktiv]					=	Source.[flag_aktiv]
				,	Target.changed_at					=	Source.changed_at	
	

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_lieferant]
			,[id_mandant]
			,[id_energieart]
			,[lieferant]
			,[lieferant_kurz]
			,[eic_nummer]
			,[id_kunde]
			,[flag_aktiv]
			,created_at
			,changed_at		
		)
		VALUES (
				Source.[id_lieferant]
			,	Source.[id_mandant]
			,	Source.[id_energieart]
			,	Source.[lieferant]
			,	Source.[lieferant_kurz]
			,	Source.[eic_nummer]
			,	Source.[id_kunde]
			,	Source.[flag_aktiv]
			,	Source.created_at
			,	Source.changed_at
		)

	;
		
	
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
