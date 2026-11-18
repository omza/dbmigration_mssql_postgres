-- Object: core.load_ablesetouren
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.ablesetouren
	

-- Change Log
	23.06.2026	OME initial
	


-- Test:

	exec core.load_ablesetouren -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_ablesetouren]
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

	MERGE INTO core.ablesetouren	AS	Target
	USING
	(
		----- QUELLE -----

		SELECT 
			[id_mandant]
			,[id_ablesetour]
			,[ablesetour]
			,[sondertour]

		FROM 
			[stage].[wilken_ablesetouren]

		----- QUELLE -----
	)
	AS Source	ON		Source.[id_mandant] = Target.[id_mandant] and Source.[id_ablesetour] = Target.[id_ablesetour]

	WHEN MATCHED  THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					Target.[ablesetour]				=	Source.[ablesetour]
				,	Target.[sondertour]				=	Source.[sondertour]
				,	Target.changed_at				=	getdate()	
	

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_mandant]
			,[id_ablesetour]
			,[ablesetour]
			,[sondertour]
		)
		VALUES (
			Source.[id_mandant]
			,Source.[id_ablesetour]
			,Source.[ablesetour]
			,Source.[sondertour]
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
