-- Object: core.load_marktlokationen
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		core.marktlokationen
	

-- Change Log

	07.02.2025	OME initial
	


-- Test:

	exec core.[load_marktlokationen] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_marktlokationen]
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

	;WITH TargetRows AS 
	(
		----- ZIEL -----

		SELECT 
			[id_malo]
			,[id_mandant]
			,[id_zp]
			,[id_energierichtung]
			,[malo]
			,[wilken_zmlk_id]
			,[wilken_mlk_id]
			,[erste_mako]
			,[created_at]
			,[changed_at]
			,[valid_from]
			,[valid_to]
			,[active]
			,CHECKSUM(
				[id_mandant]
				,[id_zp]
				,[id_energierichtung]
				,[malo]
				,[wilken_zmlk_id]
				,[wilken_mlk_id]
				,[erste_mako]
				,[created_at]
				,[changed_at]
				,[valid_from]
				,[valid_to]
				,[active]
			) AS CHECKSUM
		FROM 
			[core].[marktlokationen]

		AS	Dim


	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		select  
			[wilken_mlk_id] as id_malo
			,mnd.id_mandant 
			,id_zp 
			,id_energierichtung
			,[malo]
			,[wilken_zmlk_id]
			,[wilken_mlk_id]
			,[erste_mako]
			,mlk.[created_at]
			,mlk.[changed_at]
			,[valid_from]
			,[valid_to]
			,[active]
			,CHECKSUM(
				mnd.[id_mandant]
				,[id_zp]
				,[id_energierichtung]
				,[malo]
				,[wilken_zmlk_id]
				,[wilken_mlk_id]
				,[erste_mako]
				,mlk.[created_at]
				,mlk.[changed_at]
				,[valid_from]
				,[valid_to]
				,[active]
			) AS CHECKSUM
		from 
			[stage].[wilken_marktlokationen] mlk
		join
			core.mandant mnd on mlk.[wilken_mnd_id] = mnd.wilken_mnd_id
		join
			core.zaehlpunkte zp on mlk.wilken_zpt_id = zp.wilken_zpt_id and mnd.id_mandant = zp.id_mandant	
		left join
			core.energierichtungen er on mlk.wilken_zmlk_typ = er.wilken_zmlk_typ


		----- QUELLE -----
	)
	AS Source	ON	 Source.id_malo = Target.id_malo and Source.valid_from = Target.valid_from

	WHEN MATCHED AND Source.CHECKSUM != Target.CHECKSUM THEN

		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
				Target.changed_at	=	Source.changed_at

			,	Target.id_mandant	=	Source.id_mandant
			,	Target.id_zp	=	Source.id_zp
			,	Target.id_energierichtung	=	Source.id_energierichtung
			,	Target.[malo]	=	Source.[malo]
			,	Target.[wilken_zmlk_id]	=	Source.[wilken_zmlk_id]

			,	Target.[wilken_mlk_id]	=	Source.[wilken_mlk_id]
			,	Target.[erste_mako]	=	Source.[erste_mako]
			,	Target.[created_at]	=	Source.[created_at]

			,	Target.[valid_from]	=	Source.[valid_from]
			,	Target.[valid_to]	=	Source.[valid_to]
			,	Target.active	=	Source.active


	WHEN NOT MATCHED BY TARGET THEN

		----- INSERT, weil noch nicht vorhanden -----


		INSERT (
			[id_malo]
			,[id_mandant]
			,[id_zp]
			,[id_energierichtung]
			,[malo]
			,[wilken_zmlk_id]
			,[wilken_mlk_id]
			,[erste_mako]
			,[created_at]
			,[changed_at]
			,[valid_from]
			,[valid_to]
			,[active]
		)
		VALUES (
			Source.[id_malo]
			,	Source.[id_mandant]
			,	Source.[id_zp]
			,	Source.[id_energierichtung]
			,	Source.[malo]
			,	Source.[wilken_zmlk_id]
			,	Source.[wilken_mlk_id]
			,	Source.[erste_mako]

			,	Source.[created_at]
			,	Source.[changed_at]
			,	Source.[valid_from]
			,	Source.[valid_to]
			,	Source.[active]
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
