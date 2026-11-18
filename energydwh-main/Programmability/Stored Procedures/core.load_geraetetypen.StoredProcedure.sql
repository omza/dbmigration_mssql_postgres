-- Object: core.load_geraetetypen
-- Type  : SQL_STORED_PROCEDURE
/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.geraetetypen
	

-- Change Log

	04.02.2025	OME initial
	26.03.2025	OME	standard Gerätetypen auslagern und typen aus neuen quellsystem aufnehmen (Gerätetypen für wilhelm tel)
	14.08.2025	OME	Zaehlernenngrößen hinzu
					alter table [core].[geraetetypen] add nenngroesse varchar(40) null

-- Test:

	exec core.load_geraetetypen -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_geraetetypen]
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
		wilken verarbeitung von Zählertypen aus Wilken
	*/
	WITH TargetRows AS 
	(
		----- ZIEL -----
		SELECT 
			[id_mandant]
			,[id_energieart]
			,[id_quellsystem]
			,[geraetetyp]
			,[quellsystem_ident]
			,[quellsystem_status]
			,[created_at]
			,[changed_at]
			-- 14.08.2025
			,nenngroesse
			,CHECKSUM(
				[id_mandant]
				,[id_energieart]
				,[geraetetyp]
				,[quellsystem_status]
				,[created_at]
				,[changed_at]
				,nenngroesse
			) AS [CHECKSUM]
		FROM 
			[core].[geraetetypen] AS	Dim
		WHERE
			id_quellsystem = 1

	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		SELECT distinct
			[id_mandant]
			,[id_energieart]
			,1 [id_quellsystem]
			,[geraetetyp]
			,[wilken_ztp_nr] as [quellsystem_ident]
			,[wilken_zpt_status] as[quellsystem_status]
			,ztp.[created_at]
			,ztp.[changed_at]
			,nenngroesse
			,CHECKSUM (
				id_mandant
				,[id_energieart]
				,[geraetetyp]
				,[wilken_zpt_status]
				,ztp.[created_at]
				,ztp.[changed_at]
				,nenngroesse
			) as [CHECKSUM]
		FROM 
			[stage].[wilken_geraetetypen] ztp
		JOIN
			core.mandant mnd on ztp.[wilken_mnd_id] = mnd.wilken_mnd_id
		JOIN
			core.energiearten eart on ISNULL(ztp.[wilken_zpt_energieart], 0) = eart.id_energieart


		----- QUELLE -----
	)
	AS Source	
	
	ON		
		Source.[quellsystem_ident] = Target.[quellsystem_ident]
		and Source.[id_mandant] = Target.id_mandant
		and Source.[id_quellsystem] = Target.[id_quellsystem]

	WHEN MATCHED AND Source.[CHECKSUM] != Target.[CHECKSUM] THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 

					Target.[id_mandant] = Source.[id_mandant]
					,Target.[id_energieart] =  Source.[id_energieart]
					,Target.[geraetetyp] = Source.[geraetetyp]
					,Target.[quellsystem_status] = Source.[quellsystem_status]
					,Target.[created_at] = Source.[created_at]
					,Target.changed_at	=	Source.changed_at

					,Target.nenngroesse	=	Source.nenngroesse

				

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_mandant]
			,[id_energieart]
			,[id_quellsystem]
			,[geraetetyp]
			,[quellsystem_ident]
			,[quellsystem_status]
			,[created_at]
			,[changed_at]
			,nenngroesse
		)
		VALUES (
			Source.[id_mandant]
			,Source.[id_energieart]
			,Source.[id_quellsystem]
			,Source.[geraetetyp]
			,Source.[quellsystem_ident]
			,Source.[quellsystem_status]
			,Source.[created_at]
			,Source.[changed_at]
			,Source.nenngroesse
		);
		


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
