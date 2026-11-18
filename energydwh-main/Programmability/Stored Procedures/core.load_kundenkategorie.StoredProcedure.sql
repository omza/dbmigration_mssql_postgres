-- Object: core.load_kundenkategorie
-- Type  : SQL_STORED_PROCEDURE

/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.kundenkategorie
	

-- Change Log

	16.09.2025	OME initial
	


-- Test:

	exec core.load_kundenkategorie -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_kundenkategorie]
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


	MERGE INTO [core].kundenkategorie	AS	Target
	USING
	(
		----- QUELLE -----


		SELECT [id_mandant]
			  ,[id_kundenkategorie]
			  ,[kundenkategorie]
		  FROM [stage].[wilken_kundenkategorie]



		----- QUELLE -----
	)
	AS Source	
	ON		
		Source.[id_mandant] = Target.[id_mandant]
		and Source.[id_kundenkategorie] = Target.[id_kundenkategorie]
	
	WHEN MATCHED THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					Target.changed_at	=	GETDATE()
				,	Target.[kundenkategorie]	=	Source.[kundenkategorie]


	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
				[id_mandant]
			  ,[id_kundenkategorie]
			  ,[kundenkategorie]
		)
		VALUES (
			Source.[id_mandant]
			  ,Source.[id_kundenkategorie]
			  ,Source.[kundenkategorie]
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
