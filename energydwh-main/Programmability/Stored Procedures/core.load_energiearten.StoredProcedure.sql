-- Object: core.load_energiearten
-- Type  : SQL_STORED_PROCEDURE
/* =============================================
-- Author:		Oliver Meyer
-- Create date: 04.02.2025
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.energiearten
	

-- Change Log

	04.02.2025	OME initial
	


-- Test:

	exec core.load_energiearten -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_energiearten]
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

	WITH energiearten as 
	(
	  SELECT
		cast([ENA_NR] as int) id_energieart,
		[ENA_BEZEICHNUNG] as energieart,
		row_number() over (partition by ENA_NR order by ISNULL(ENA_GEAENDERT,ENA_ANGELEGT) desc) as Row#
	  FROM 
		raw.wilken_crena
	)

	,TargetRows AS 
	(
		----- ZIEL -----
		SELECT 
			[id_energieart]
			,energieart
			,changed_at
		FROM 
			[core].[energiearten]	AS	Dim


	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		select 
			id_energieart,
			energieart
		from
			energiearten
		where
			row# = 1
		----- QUELLE -----
	)
	AS Source	ON		Source.id_energieart = Target.id_energieart

	WHEN MATCHED AND Source.energieart != Target.energieart THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					Target.changed_at	=	GETDATE()
				,	Target.energieart	=	Source.energieart


	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			id_energieart
           ,energieart
		)
		VALUES (
				Source.id_energieart
			,	Source.energieart

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
