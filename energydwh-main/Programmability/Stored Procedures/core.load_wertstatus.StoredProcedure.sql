-- Object: core.load_wertstatus
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Create date: 04.02.2025
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		
		core.wertstatus
	

-- Change Log

	27.03.2025	OME initial
	25.04.2025	OME	Ändern auf View für argos wertstatus
	


-- Test:

	exec core.[load_wertstatus] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_wertstatus]
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
		Pflege Argos Wertstatus Tabelle
	*/
	;WITH TargetRows AS 
	(
		----- ZIEL -----

		SELECT 
			[id_wertstatus]
			,[wertstatus]
			,[argos_wertstatus]
			,changed_at
		FROM 
			[core].[wertstatus] AS	Dim


	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		select
			[argos_wertstatus] as [id_wertstatus],
			[argos_wertstatus],
			[wertstatus]
		from
			[stage].[argos_file_werte]
		group by
			[argos_wertstatus],
			[wertstatus]
		----- QUELLE -----
	)
	AS Source	ON		Source.[argos_wertstatus] = Target.[argos_wertstatus]

	WHEN MATCHED AND Source.[wertstatus] != Target.[wertstatus] THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					Target.changed_at	=	GETDATE()
				,	Target.[wertstatus]	=	Source.[wertstatus]


	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_wertstatus]
			,[wertstatus]
			,[argos_wertstatus]
		)
		VALUES (
				Source.[id_wertstatus]
			,	Source.[wertstatus]
			,	Source.[argos_wertstatus]
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
