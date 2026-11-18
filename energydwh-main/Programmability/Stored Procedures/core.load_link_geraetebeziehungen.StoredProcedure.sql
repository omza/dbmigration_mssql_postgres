-- Object: core.load_link_geraetebeziehungen
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.link_geraetebeziehungen 
	

-- Change Log

	22.06.2026	OME initial
	


-- Test:

	exec core.load_link_geraetebeziehungen -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_link_geraetebeziehungen]
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

	;WITH TargetRows AS 
	(
		----- ZIEL -----
		select  
			[id_link_geraet_geraet]
			,[id_quellsystem]
			,[id_beziehnungsart]
			,[beziehungsart]
			,[gueltig_von]
			,[gueltig_bis]
			,[id_status_geraetebeziehung]
			,[master_id_geraet]
			,[master_quellsystem_ident]
			,[master_geraetenummer]
			,[master_id_mandant]
			,[master_id_energieart]
			,[master_einbaudatum]
			,[master_ausbaudatum]
			,[master_id_status]
			,[master_status]
			,[slave_id_geraet]
			,[slave_quellsystem_ident]
			,[slave_geraetenummer]
			,[slave_id_mandant]
			,[slave_id_energieart]
			,[slave_einbaudatum]
			,[slave_ausbaudatum]
			,[slave_id_status]
			,[slave_status]

			,CHECKSUM(
				[id_quellsystem]
				,[id_beziehnungsart]
				,[beziehungsart]
				,[gueltig_von]
				,[gueltig_bis]
				,[id_status_geraetebeziehung]
				,[master_id_geraet]
				,[master_quellsystem_ident]
				,[master_geraetenummer]
				,[master_id_mandant]
				,[master_id_energieart]
				,[master_einbaudatum]
				,[master_ausbaudatum]
				,[master_id_status]
				,[master_status]
				,[slave_id_geraet]
				,[slave_quellsystem_ident]
				,[slave_geraetenummer]
				,[slave_id_mandant]
				,[slave_id_energieart]
				,[slave_einbaudatum]
				,[slave_ausbaudatum]
				,[slave_id_status]
				,[slave_status]
			) AS [checksum]
		from 
			[core].[link_geraetebeziehungen] 
	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----

		select  
			[id_link_geraet_geraet]
			,[id_quellsystem]
			,[id_beziehnungsart]
			,[beziehungsart]
			,[gueltig_von]
			,[gueltig_bis]
			,[id_status_geraetebeziehung]
			,[master_id_geraet]
			,[master_quellsystem_ident]
			,[master_geraetenummer]
			,[master_id_mandant]
			,[master_id_energieart]
			,[master_einbaudatum]
			,[master_ausbaudatum]
			,[master_id_status]
			,[master_status]
			,[slave_id_geraet]
			,[slave_quellsystem_ident]
			,[slave_geraetenummer]
			,[slave_id_mandant]
			,[slave_id_energieart]
			,[slave_einbaudatum]
			,[slave_ausbaudatum]
			,[slave_id_status]
			,[slave_status]
			,CHECKSUM(
				[id_quellsystem]
				,[id_beziehnungsart]
				,[beziehungsart]
				,[gueltig_von]
				,[gueltig_bis]
				,[id_status_geraetebeziehung]
				,[master_id_geraet]
				,[master_quellsystem_ident]
				,[master_geraetenummer]
				,[master_id_mandant]
				,[master_id_energieart]
				,[master_einbaudatum]
				,[master_ausbaudatum]
				,[master_id_status]
				,[master_status]
				,[slave_id_geraet]
				,[slave_quellsystem_ident]
				,[slave_geraetenummer]
				,[slave_id_mandant]
				,[slave_id_energieart]
				,[slave_einbaudatum]
				,[slave_ausbaudatum]
				,[slave_id_status]
				,[slave_status]
			) AS [checksum] 
		from 
			stage.wilken_geraetebeziehungen

		----- QUELLE -----
	)
	AS Source	ON		Source.[id_link_geraet_geraet] = Target.[id_link_geraet_geraet]

	WHEN MATCHED and Target.[checksum] <> Source.[checksum] THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
			Target.[id_quellsystem]                    = Source.[id_quellsystem]
			,Target.[id_beziehnungsart]                 = Source.[id_beziehnungsart]
			,Target.[beziehungsart]                     = Source.[beziehungsart]
			,Target.[gueltig_von]                       = Source.[gueltig_von]
			,Target.[gueltig_bis]                       = Source.[gueltig_bis]
			,Target.[id_status_geraetebeziehung]        = Source.[id_status_geraetebeziehung]
			,Target.[master_id_geraet]                  = Source.[master_id_geraet]
			,Target.[master_quellsystem_ident]          = Source.[master_quellsystem_ident]
			,Target.[master_geraetenummer]              = Source.[master_geraetenummer]
			,Target.[master_id_mandant]                 = Source.[master_id_mandant]
			,Target.[master_id_energieart]              = Source.[master_id_energieart]
			,Target.[master_einbaudatum]                = Source.[master_einbaudatum]
			,Target.[master_ausbaudatum]                = Source.[master_ausbaudatum]
			,Target.[master_id_status]                  = Source.[master_id_status]
			,Target.[master_status]                     = Source.[master_status]
			,Target.[slave_id_geraet]                   = Source.[slave_id_geraet]
			,Target.[slave_quellsystem_ident]           = Source.[slave_quellsystem_ident]
			,Target.[slave_geraetenummer]               = Source.[slave_geraetenummer]
			,Target.[slave_id_mandant]                  = Source.[slave_id_mandant]
			,Target.[slave_id_energieart]               = Source.[slave_id_energieart]
			,Target.[slave_einbaudatum]                 = Source.[slave_einbaudatum]
			,Target.[slave_ausbaudatum]                 = Source.[slave_ausbaudatum]
			,Target.[slave_id_status]                   = Source.[slave_id_status]
			,Target.[slave_status]                      = Source.[slave_status]
	

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_link_geraet_geraet]
			,[id_quellsystem]
			,[id_beziehnungsart]
			,[beziehungsart]
			,[gueltig_von]
			,[gueltig_bis]
			,[id_status_geraetebeziehung]
			,[master_id_geraet]
			,[master_quellsystem_ident]
			,[master_geraetenummer]
			,[master_id_mandant]
			,[master_id_energieart]
			,[master_einbaudatum]
			,[master_ausbaudatum]
			,[master_id_status]
			,[master_status]
			,[slave_id_geraet]
			,[slave_quellsystem_ident]
			,[slave_geraetenummer]
			,[slave_id_mandant]
			,[slave_id_energieart]
			,[slave_einbaudatum]
			,[slave_ausbaudatum]
			,[slave_id_status]
			,[slave_status]
		)
		VALUES (
			Source.[id_link_geraet_geraet]
			,Source.[id_quellsystem]
			,Source.[id_beziehnungsart]
			,Source.[beziehungsart]
			,Source.[gueltig_von]
			,Source.[gueltig_bis]
			,Source.[id_status_geraetebeziehung]
			,Source.[master_id_geraet]
			,Source.[master_quellsystem_ident]
			,Source.[master_geraetenummer]
			,Source.[master_id_mandant]
			,Source.[master_id_energieart]
			,Source.[master_einbaudatum]
			,Source.[master_ausbaudatum]
			,Source.[master_id_status]
			,Source.[master_status]
			,Source.[slave_id_geraet]
			,Source.[slave_quellsystem_ident]
			,Source.[slave_geraetenummer]
			,Source.[slave_id_mandant]
			,Source.[slave_id_energieart]
			,Source.[slave_einbaudatum]
			,Source.[slave_ausbaudatum]
			,Source.[slave_id_status]
			,Source.[slave_status]
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
