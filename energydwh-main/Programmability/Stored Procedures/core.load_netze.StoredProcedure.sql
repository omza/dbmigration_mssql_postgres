-- Object: core.load_netze
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Create date: 30.06.2025
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.netze 
	

-- Change Log

	26.02.2025	OME initial
	


-- Test:

	exec core.load_netze -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_netze]
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

	MERGE INTO core.netze	AS	Target
	USING
	(
		----- QUELLE -----

		SELECT 
			[id_netz]
			,[id_mandant]
			,[id_energieart]
			,[netz_nummer]
			,[netz]
			,[netz_status]
			,[eigenes_netz]
			,[grundversorger_netz]
			,[kunden_netz]
			,created_at
			,changed_at
		FROM 
			[stage].[wilken_netze]

		----- QUELLE -----
	)
	AS Source	ON		Source.[id_netz] = Target.[id_netz]

	WHEN MATCHED  THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					Target.[id_mandant]				=	Source.[id_mandant]
				,	Target.[id_energieart]			=	Source.[id_energieart]
				,	Target.[netz_nummer]			=	Source.[netz_nummer]
				,	Target.[netz]					=	Source.[netz]

				,	Target.[netz_status]			=	Source.[netz_status]
				,	Target.[eigenes_netz]			=	Source.[eigenes_netz]
				,	Target.[grundversorger_netz]	=	Source.[grundversorger_netz]
				,	Target.[kunden_netz]			=	Source.[kunden_netz]
				,	Target.created_at				=	Source.created_at
				,	Target.changed_at				=	Source.changed_at	
	

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_netz]
			,[id_mandant]
			,[id_energieart]
			,[netz_nummer]
			,[netz]
			,[netz_status]
			,[eigenes_netz]
			,[grundversorger_netz]
			,[kunden_netz]
			,created_at
			,changed_at	
		)
		VALUES (
			Source.[id_netz]
			,Source.[id_mandant]
			,Source.[id_energieart]
			,Source.[netz_nummer]
			,Source.[netz]
			,Source.[netz_status]
			,Source.[eigenes_netz]
			,Source.[grundversorger_netz]
			,Source.[kunden_netz]
			,Source.created_at
			,Source.changed_at
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
