-- Object: core.load_geraete
-- Type  : SQL_STORED_PROCEDURE

/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.geraete
	

-- Change Log

	15.12.2025	OME initial
	18.06.2026	OMe	Gasdruck für Regler hinzu

-- Test:

	exec core.load_geraete -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_geraete]
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

	MERGE INTO [core].[geraete]	AS	Target
	USING
	(
		----- QUELLE -----
		select 
			[id_mandant]
			,[id_geraet]
			,[id_quellsystem]
			,[quellsystem_ident]
			,[geraetenummer]
			,[id_energieart]
			,[id_geraeteart]
			,[id_geraetetyp]
			,[id_standardgeraetetyp]
			,[baujahr]
			,[eichung]
			,[naechste_eichung]
			,[los_nummer]
			,[id_losstatus]
			,[id_lagerstatus]
			,[zaehler_energierichtungen]
			,[zaehlerpin]
			,gasdruck
			,[created_at]
			,[changed_at] 
		from 
			stage.wilken_geraete

		----- QUELLE -----
	)
	AS Source	
	
	ON		
		Source.[id_geraet] = Target.[id_geraet]

	WHEN MATCHED THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 

			Target.[id_mandant]                     = Source.[id_mandant]               
			,Target.[id_geraet]                      = Source.[id_geraet]                
			,Target.[id_quellsystem]                 = Source.[id_quellsystem]           
			,Target.[quellsystem_ident]              = Source.[quellsystem_ident]        
			,Target.[geraetenummer]                  = Source.[geraetenummer]            
			,Target.[id_energieart]                  = Source.[id_energieart]            
			,Target.[id_geraeteart]                  = Source.[id_geraeteart]            
			,Target.[id_geraetetyp]                  = Source.[id_geraetetyp]            
			,Target.[id_standardgeraetetyp]          = Source.[id_standardgeraetetyp]    
			,Target.[baujahr]                        = Source.[baujahr]                  
			,Target.[eichung]                        = Source.[eichung]                  
			,Target.[naechste_eichung]               = Source.[naechste_eichung]         
			,Target.[los_nummer]                     = Source.[los_nummer]               
			,Target.[id_losstatus]                   = Source.[id_losstatus]             
			,Target.[id_lagerstatus]                 = Source.[id_lagerstatus]           
			,Target.[zaehler_energierichtungen]      = Source.[zaehler_energierichtungen]
			,Target.[zaehlerpin]                     = Source.[zaehlerpin]               
			,Target.gasdruck						= Source.gasdruck      
			,Target.[created_at]                     = Source.[created_at]               
			,Target.[changed_at]                     = Source.[changed_at]     

				

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_mandant]
			,[id_geraet]
			,[id_quellsystem]
			,[quellsystem_ident]
			,[geraetenummer]
			,[id_energieart]
			,[id_geraeteart]
			,[id_geraetetyp]
			,[id_standardgeraetetyp]
			,[baujahr]
			,[eichung]
			,[naechste_eichung]
			,[los_nummer]
			,[id_losstatus]
			,[id_lagerstatus]
			,[zaehler_energierichtungen]
			,[zaehlerpin]
			,gasdruck
			,[created_at]
			,[changed_at] 
		)
		VALUES (
			Source.[id_mandant]               
			,Source.[id_geraet]                
			,Source.[id_quellsystem]           
			,Source.[quellsystem_ident]        
			,Source.[geraetenummer]            
			,Source.[id_energieart]            
			,Source.[id_geraeteart]            
			,Source.[id_geraetetyp]            
			,Source.[id_standardgeraetetyp]    
			,Source.[baujahr]                  
			,Source.[eichung]                  
			,Source.[naechste_eichung]         
			,Source.[los_nummer]               
			,Source.[id_losstatus]             
			,Source.[id_lagerstatus]           
			,Source.[zaehler_energierichtungen]
			,Source.[zaehlerpin]
			,Source.gasdruck
			,Source.[created_at]               
			,Source.[changed_at]               
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
