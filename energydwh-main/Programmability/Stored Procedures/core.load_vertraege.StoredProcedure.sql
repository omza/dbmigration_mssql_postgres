-- Object: core.load_vertraege
-- Type  : SQL_STORED_PROCEDURE



/* =============================================
-- Author:		Oliver Meyer
-- Create date: 26.02.2026
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.vertraege
	

-- Change Log

	26.02.2026	OME initial
	


-- Test:

	exec core.load_vertraege -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_vertraege]
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
			[id_vertrag]
           ,[id_mandant]
           ,[id_energieart]
           ,[vertragsnummer]
           ,[id_vertragsart]
           ,[vertragsbeginn]
           ,[vertragsende]
           ,[vertragsbindung_bis]
           ,[id_vertragsstatus]
           ,[vertrag_gekuendigt_zum]
           ,[id_produkt]
           ,[id_produktvariante]
           ,[grundversorgung]
           ,[kuendigungsfrist_ablauf]
           ,[belieferung_ab]
           ,[belieferung_bis]
           ,[created_at]
           ,[changed_at]
			,CHECKSUM(
				[id_vertrag]
			   ,[id_mandant]
			   ,[id_energieart]
			   ,[vertragsnummer]
			   ,[id_vertragsart]
			   ,[vertragsbeginn]
			   ,[vertragsende]
			   ,[vertragsbindung_bis]
			   ,[id_vertragsstatus]
			   ,[vertrag_gekuendigt_zum]
			   ,[id_produkt]
			   ,[id_produktvariante]
			   ,[grundversorgung]
			   ,[kuendigungsfrist_ablauf]
			   ,[belieferung_ab]
			   ,[belieferung_bis]
			   ,[created_at]
			   ,[changed_at]
			) AS CHECKSUM
		  FROM [core].vertraege	AS	Dim


	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		select
			[id_vertrag]
			,[id_mandant]
			,[id_energieart]
			,[vertragsnummer]
			,[id_vertragsart]
			,[vertragsbeginn]
			,[vertragsende]
			,[vertragsbindung_bis]
			,[id_vertragsstatus]
			,[vertrag_gekuendigt_zum]
			,[id_produkt]
			,[id_produktvariante]
			,[grundversorgung]
			,[kuendigungsfrist_ablauf]
			,[belieferung_ab]
			,[belieferung_bis]
			,[created_at]
			,[changed_at]
			,CHECKSUM(
				[id_vertrag]
			   ,[id_mandant]
			   ,[id_energieart]
			   ,[vertragsnummer]
			   ,[id_vertragsart]
			   ,[vertragsbeginn]
			   ,[vertragsende]
			   ,[vertragsbindung_bis]
			   ,[id_vertragsstatus]
			   ,[vertrag_gekuendigt_zum]
			   ,[id_produkt]
			   ,[id_produktvariante]
			   ,[grundversorgung]
			   ,[kuendigungsfrist_ablauf]
			   ,[belieferung_ab]
			   ,[belieferung_bis]
			   ,[created_at]
			   ,[changed_at]
			) AS CHECKSUM
		FROM 
			[stage].[wilken_vertraege]
		----- QUELLE -----
	)
	AS Source	ON		Source.[id_vertrag] = Target.[id_vertrag]

	WHEN MATCHED AND Source.[CHECKSUM] != Target.[CHECKSUM] THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
			 Target.[id_vertrag]                    = Source.[id_vertrag]
			,Target.[id_mandant]                    = Source.[id_mandant]
			,Target.[id_energieart]                 = Source.[id_energieart]
			,Target.[vertragsnummer]                = Source.[vertragsnummer]
			,Target.[id_vertragsart]                = Source.[id_vertragsart]
			,Target.[vertragsbeginn]                = Source.[vertragsbeginn]
			,Target.[vertragsende]                  = Source.[vertragsende]
			,Target.[vertragsbindung_bis]           = Source.[vertragsbindung_bis]
			,Target.[id_vertragsstatus]             = Source.[id_vertragsstatus]
			,Target.[vertrag_gekuendigt_zum]        = Source.[vertrag_gekuendigt_zum]
			,Target.[id_produkt]                    = Source.[id_produkt]
			,Target.[id_produktvariante]            = Source.[id_produktvariante]
			,Target.[grundversorgung]               = Source.[grundversorgung]
			,Target.[kuendigungsfrist_ablauf]       = Source.[kuendigungsfrist_ablauf]
			,Target.[belieferung_ab]                = Source.[belieferung_ab]
			,Target.[belieferung_bis]               = Source.[belieferung_bis]
			,Target.[created_at]                    = Source.[created_at]
			,Target.[changed_at]                    = Source.[changed_at]
	

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_vertrag]
			,[id_mandant]
			,[id_energieart]
			,[vertragsnummer]
			,[id_vertragsart]
			,[vertragsbeginn]
			,[vertragsende]
			,[vertragsbindung_bis]
			,[id_vertragsstatus]
			,[vertrag_gekuendigt_zum]
			,[id_produkt]
			,[id_produktvariante]
			,[grundversorgung]
			,[kuendigungsfrist_ablauf]
			,[belieferung_ab]
			,[belieferung_bis]
			,[created_at]
			,[changed_at]
		)
		VALUES (
			 Source.[id_vertrag]
			,Source.[id_mandant]
			,Source.[id_energieart]
			,Source.[vertragsnummer]
			,Source.[id_vertragsart]
			,Source.[vertragsbeginn]
			,Source.[vertragsende]
			,Source.[vertragsbindung_bis]
			,Source.[id_vertragsstatus]
			,Source.[vertrag_gekuendigt_zum]
			,Source.[id_produkt]
			,Source.[id_produktvariante]
			,Source.[grundversorgung]
			,Source.[kuendigungsfrist_ablauf]
			,Source.[belieferung_ab]
			,Source.[belieferung_bis]
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
