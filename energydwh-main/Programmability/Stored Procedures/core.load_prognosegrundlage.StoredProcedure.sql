-- Object: core.load_prognosegrundlage
-- Type  : SQL_STORED_PROCEDURE



/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		
		core.schlüsseldefinitionen für prognosegrundlage
	

-- Change Log

	20.10.2026	OME initial

	


-- Test:

	exec core.[load_prognosegrundlage] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_prognosegrundlage]
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

	MERGE INTO [core].[schluesseldefinition]	AS	Target
	USING
	(
		----- QUELLE -----
		SELECT 
			'id_prognosegrundlage' [feldname]
			,ltrim(rtrim(cast([PRGG_NR] as VARCHAR(50)))) as wert
			,ltrim(rtrim(left([PRGG_BEZEICHNUNG],50))) as [definition]
		FROM 
			[raw].[wilken_edprggrundlage]
		where
			[PRGG_NR] > 0
		----- QUELLE -----
	)
	AS Source	ON		Source.[feldname] = Target.[feldname]
						and Source.wert = Target.wert

	WHEN MATCHED AND Source.[definition] != Target.[definition] THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
			Target.[definition]	=	Source.[definition]


	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[feldname]
			,[wert]
			,[definition]
		)
		VALUES (
				Source.[feldname]
			,	Source.[wert]
			,	Source.[definition]
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
