-- Object: core.load_produkte
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Create date: 26.02.2026
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.produkte
	

-- Change Log

	26.02.2026	OME initial
	


-- Test:

	exec core.load_produkte -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_produkte]
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
			[id_produkt]
			,[id_produktvariante]
			,[id_energieart]
			,[id_produktart]
			,[produkt_nummer]
			,[produkt]
			,[produkt_publikationsbezeichnung]
			,[variante_nummer]
			,[variante]
			,[variante_publikationsbezeichnung]
			,[gueltig_von]
			,[gueltig_bis]
			,[produkt_status]
			,[variante_status]
			,[created_at]
			,[changed_at]
			,CHECKSUM(
				[id_produkt]
				,[id_produktvariante]
				,[id_energieart]
				,[id_produktart]
				,[produkt_nummer]
				,[produkt]
				,[produkt_publikationsbezeichnung]
				,[variante_nummer]
				,[variante]
				,[variante_publikationsbezeichnung]
				,[gueltig_von]
				,[gueltig_bis]
				,[produkt_status]
				,[variante_status]
				,[created_at]
				,[changed_at]
			) AS CHECKSUM
		  FROM [core].produkte	AS	Dim


	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		select
			[id_produkt]
			,[id_produktvariante]
			,[id_energieart]
			,[id_produktart]
			,[produkt_nummer]
			,[produkt]
			,[produkt_publikationsbezeichnung]
			,[variante_nummer]
			,[variante]
			,[variante_publikationsbezeichnung]
			,[gueltig_von]
			,[gueltig_bis]
			,[produkt_status]
			,[variante_status]
			,[created_at]
			,[changed_at]
			,CHECKSUM(
				[id_produkt]
				,[id_produktvariante]
				,[id_energieart]
				,[id_produktart]
				,[produkt_nummer]
				,[produkt]
				,[produkt_publikationsbezeichnung]
				,[variante_nummer]
				,[variante]
				,[variante_publikationsbezeichnung]
				,[gueltig_von]
				,[gueltig_bis]
				,[produkt_status]
				,[variante_status]
				,[created_at]
				,[changed_at]
			) AS CHECKSUM
		FROM 
			[stage].[wilken_produkte]
		----- QUELLE -----
	)
	AS Source	ON		Source.[id_produkt] = Target.[id_produkt] and Source.[id_produktvariante] = Target.[id_produktvariante] 

	WHEN MATCHED AND Source.[CHECKSUM] != Target.[CHECKSUM] THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
			 Target.[id_produkt]							= Source.[id_produkt]						
			,Target.[id_produktvariante]                    = Source.[id_produktvariante]
			,Target.[id_energieart]                         = Source.[id_energieart]
			,Target.[id_produktart]                         = Source.[id_produktart]
			,Target.[produkt_nummer]                        = Source.[produkt_nummer]
			,Target.[produkt]                               = Source.[produkt]
			,Target.[produkt_publikationsbezeichnung]       = Source.[produkt_publikationsbezeichnung]
			,Target.[variante_nummer]                       = Source.[variante_nummer]
			,Target.[variante]                              = Source.[variante]
			,Target.[variante_publikationsbezeichnung]      = Source.[variante_publikationsbezeichnung]
			,Target.[gueltig_von]                           = Source.[gueltig_von]
			,Target.[gueltig_bis]                           = Source.[gueltig_bis]
			,Target.[produkt_status]                        = Source.[produkt_status]
			,Target.[variante_status]                       = Source.[variante_status]
			,Target.[created_at]                            = Source.[created_at]
			,Target.[changed_at]                            = Source.[changed_at]
	

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_produkt]
			,[id_produktvariante]
			,[id_energieart]
			,[id_produktart]
			,[produkt_nummer]
			,[produkt]
			,[produkt_publikationsbezeichnung]
			,[variante_nummer]
			,[variante]
			,[variante_publikationsbezeichnung]
			,[gueltig_von]
			,[gueltig_bis]
			,[produkt_status]
			,[variante_status]
			,[created_at]
			,[changed_at]
		)
		VALUES (
			 Source.[id_produkt]
			,Source.[id_produktvariante]
			,Source.[id_energieart]
			,Source.[id_produktart]
			,Source.[produkt_nummer]
			,Source.[produkt]
			,Source.[produkt_publikationsbezeichnung]
			,Source.[variante_nummer]
			,Source.[variante]
			,Source.[variante_publikationsbezeichnung]
			,Source.[gueltig_von]
			,Source.[gueltig_bis]
			,Source.[produkt_status]
			,Source.[variante_status]
			,Source.[created_at]
			,Source.[changed_at]
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
