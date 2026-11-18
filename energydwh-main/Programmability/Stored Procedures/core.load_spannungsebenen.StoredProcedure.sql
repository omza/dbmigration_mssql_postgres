-- Object: core.load_spannungsebenen
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
	
	Führt  die notwendigen Aktualisierungen durch für: core.spannungsebenen
	

-- Change Log

	18.06.2026	OME initial
	


-- Test:

	exec [core].[load_spannungsebenen] -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_spannungsebenen]
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

	MERGE INTO [core].[spannungsebenen]	AS	Target
	USING
	(
		----- QUELLE -----

		SELECT 
			[id_spannungsebene]
			,[id_mandant]
			,[id_energieart]
			,[spannungsebene]
			,[edicode]
			,[created_at]
			,[changed_at]
		FROM 
			[stage].[wilken_spannungsebenen]

		----- QUELLE -----
	)
	AS 
		Source	
	ON		
		Source.[id_spannungsebene] = Target.[id_spannungsebene]
		and Source.[id_mandant] = Target.id_mandant


	WHEN MATCHED  THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					
					Target.[id_energieart]			=	Source.[id_energieart]
				,	Target.[spannungsebene]			=	Source.[spannungsebene]
				,	Target.[edicode]					=	Source.[edicode]


				,	Target.created_at				=	Source.created_at
				,	Target.changed_at				=	Source.changed_at	
	

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_spannungsebene]
			,[id_mandant]
			,[id_energieart]
			,[spannungsebene]
			,[edicode]
			,[created_at]
			,[changed_at]
		)
		VALUES (
			Source.[id_spannungsebene]
			,Source.[id_mandant]
			,Source.[id_energieart]
			,Source.[spannungsebene]
			,Source.[edicode]
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
