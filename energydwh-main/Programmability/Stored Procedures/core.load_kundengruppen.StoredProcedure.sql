-- Object: core.load_kundengruppen
-- Type  : SQL_STORED_PROCEDURE

/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.kundengruppen
	

-- Change Log

	16.09.2025	OME initial
	


-- Test:

	exec core.load_kundengruppen -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_kundengruppen]
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


	MERGE INTO [core].[kundengruppen]	AS	Target
	USING
	(
		----- QUELLE -----


		SELECT [id_mandant]
			  ,[id_kundengruppe]
			  ,[kundengruppe]
			  ,[created_at]
			  ,[changed_at]
		  FROM [stage].[wilken_kundengruppen]



		----- QUELLE -----
	)
	AS Source	
	ON		
		Source.[id_mandant] = Target.[id_mandant]
		and Source.[id_kundengruppe] = Target.[id_kundengruppe]
	
	WHEN MATCHED THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					Target.changed_at	=	Source.[changed_at]
				,	Target.[kundengruppe]	=	Source.[kundengruppe]


	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
				[id_mandant]
			  ,[id_kundengruppe]
			  ,[kundengruppe]
			  ,[created_at]
			  ,[changed_at]
		)
		VALUES (
			Source.[id_mandant]
			  ,Source.[id_kundengruppe]
			  ,Source.[kundengruppe]
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
