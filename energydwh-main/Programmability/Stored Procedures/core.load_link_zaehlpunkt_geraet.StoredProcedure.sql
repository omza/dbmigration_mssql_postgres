-- Object: core.load_link_zaehlpunkt_geraet
-- Type  : SQL_STORED_PROCEDURE

/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.link_zaehlpunkt_geraet
	

-- Change Log

	15.12.2025	OME initial

-- Test:

	exec core.load_link_zaehlpunkt_geraet -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_link_zaehlpunkt_geraet]
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
		wilken verarbeitung von Geratestammdaten aus Wilken
	*/

	MERGE INTO [core].[link_zaehlpunkt_geraet]	AS	Target
	USING
	(
		----- QUELLE -----
		select 
			[id_link_zp_geraet]
			,[id_mandant]
			,[id_energieart]
			,[id_zp]
			,[id_geraet]
			,[einbaudatum]
			,[ausbaudatum]
			,[id_status]
			,[status]
			,[created_at]
			,[changed_at]
			,[active]
		from 
			stage.[wilken_link_zaehlpunkt_geraet]

		----- QUELLE -----
	)
	AS Source	
	
	ON		
		Source.[id_link_zp_geraet] = Target.[id_link_zp_geraet]

	WHEN MATCHED THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 

			Target.[id_mandant]     = Source.[id_mandant]
			,Target.[id_energieart]  = Source.[id_energieart]
			,Target.[id_zp]          = Source.[id_zp]
			,Target.[id_geraet]      = Source.[id_geraet]
			,Target.[einbaudatum]    = Source.[einbaudatum]
			,Target.[ausbaudatum]    = Source.[ausbaudatum]
			,Target.[id_status]      = Source.[id_status]
			,Target.[status]         = Source.[status]
			,Target.[created_at]     = Source.[created_at]
			,Target.[changed_at]     = Source.[changed_at]
			,Target.[active]         = Source.[active]   

				

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_link_zp_geraet]
			,[id_mandant]
			,[id_energieart]
			,[id_zp]
			,[id_geraet]
			,[einbaudatum]
			,[ausbaudatum]
			,[id_status]
			,[status]
			,[created_at]
			,[changed_at]
			,[active]
		)
		VALUES (
			Source.[id_link_zp_geraet]
			,Source.[id_mandant]
			,Source.[id_energieart]
			,Source.[id_zp]
			,Source.[id_geraet]
			,Source.[einbaudatum]
			,Source.[ausbaudatum]
			,Source.[id_status]
			,Source.[status]
			,Source.[created_at]
			,Source.[changed_at]
			,Source.[active]             
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
