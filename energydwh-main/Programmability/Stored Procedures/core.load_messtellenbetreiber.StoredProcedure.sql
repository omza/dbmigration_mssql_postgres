-- Object: core.load_messtellenbetreiber
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.messtellenbetreiber 
	

-- Change Log

	08.09.2026	OME initial
	


-- Test:

	exec core.load_messtellenbetreiber -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_messtellenbetreiber]
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

	MERGE INTO core.messstellenbetreiber	AS	Target
	USING
	(
		----- QUELLE -----

		select 
			[id_messstellenbetreiber]
			,[id_mandant]
			,[id_energieart]
			,[messstellenbetreiber]
			,[eigener_messstellenbetreiber]
			,[aktiver_messstellenbetreiber]
			,[id_kunde]
			,[created_at]
			,[changed_at]
		from 
			[stage].[wilken_messstellenbetreiber]

		----- QUELLE -----
	)
	AS 
		Source	
	ON		

		Source.[id_messstellenbetreiber] = Target.[id_messstellenbetreiber]

	WHEN MATCHED  THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					Target.[id_energieart]					=	Source.[id_energieart]
				,	Target.[id_mandant]						=	Source.[id_mandant]
				,	Target.[messstellenbetreiber]			=	Source.[messstellenbetreiber]

				,	Target.[eigener_messstellenbetreiber]	=	Source.[eigener_messstellenbetreiber]
				,	Target.[aktiver_messstellenbetreiber]	=	Source.[aktiver_messstellenbetreiber]
				,	Target.[id_kunde]						=	Source.[id_kunde]

				,	Target.created_at						=	Source.created_at
				,	Target.changed_at						=	Source.changed_at	
	

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_messstellenbetreiber]
			,[id_mandant]
			,[id_energieart]
			,[messstellenbetreiber]
			,[eigener_messstellenbetreiber]
			,[aktiver_messstellenbetreiber]
			,[id_kunde]
			,[created_at]
			,[changed_at]
		)
		VALUES (
			Source.[id_messstellenbetreiber]
			,Source.[id_mandant]
			,Source.[id_energieart]
			,Source.[messstellenbetreiber]
			,Source.[eigener_messstellenbetreiber]
			,Source.[aktiver_messstellenbetreiber]
			,Source.[id_kunde]
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
