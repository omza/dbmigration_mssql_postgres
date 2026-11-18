-- Object: core.load_mandant
-- Type  : SQL_STORED_PROCEDURE

/* =============================================
-- Author:		Oliver Meyer
-- Create date: 04.02.2025
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		core.mandant
	

-- Change Log

	04.02.2025	OME initial
	11.03.2025	OMe	Mandanten auch aus P5 übernehmen wenn Nummer noch nicht in Energy vergeben


-- Test:

	exec core.[load_mandant] -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_mandant]
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
			[id_mandant]
			,[mandant]
			,[wilken_mnd_id]
			,[wilken_konzern]
			,[wilken_gpmandant]
			,created_at
			,[changed_at]
			,CHECKSUM(
				[mandant]
				,[wilken_mnd_id]
				,[wilken_konzern]
				,[wilken_gpmandant]
			) as CHECKSUM
		FROM 
			[core].[mandant]
		AS	Dim


	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		SELECT distinct 
			cast(MND_ID as int) as id_mandant
			,ltrim(rtrim([MND_NAME])) as mandant
			,MND_ID as wilken_mnd_id
			,[MND_KONZERN] as wilken_konzern
			,[MND_GPMANDANT] as wilken_gpmandant
			,CHECKSUM(
				ltrim(rtrim([MND_NAME]))
				,MND_ID
				,[MND_KONZERN]
				,[MND_GPMANDANT]
			) as CHECKSUM
			,[MND_ANGELEGT] as created_at
			,isnull([MND_GEAENDERT],[MND_ANGELEGT]) as changed_at
		  FROM 
				[raw].[wilken_enmnd]
		UNION
			
  		SELECT distinct
			cast(Y10.Y10MANDA as int) as id_mandant,
			LTRIM(RTRIM(Y04.Y04BEZEI)) as mandant,
			Y10.Y10MANDA as wilken_mnd_id,
			Y10.Y10KNZNR as wilken_konzern,
			Y10.Y10MANDA as wilken_gpmandant,
			CHECKSUM(
				LTRIM(RTRIM(Y04.Y04BEZEI))
				,Y10.Y10MANDA
				,Y10.Y10KNZNR
				,Y10.Y10MANDA
			) as CHECKSUM,				
			CONVERT(datetime, '01.01.1900',104) as created_at,
			CONVERT(datetime, CAST(Y10.Y10TMSTP1 as CHAR(10)),120) as changed_at
		FROM
			RealDWH.[STAGE].[WILKEN_CSY10020] Y10 WITH (NOLOCK)
		JOIN
			RealDWH.STAGE.WILKEN_CSY04020 Y04 ON Y10.Y10REFBZ = Y04.Y04REFBZ AND Y10.Y10SPRAC = Y04.Y04SPRAC AND Y10.Y10SPRAC = 'D'
		WHERE
			Y10KNZNR = 'N' AND Y10MANDA <> '' AND Y10WERKE = ''	
			AND cast(Y10.Y10MANDA as int) NOT IN (SELECT cast(MND_ID as int) from [raw].[wilken_enmnd])
		----- QUELLE -----
	)
	AS Source	ON		Source.id_mandant = Target.id_mandant

	WHEN MATCHED AND Source.CHECKSUM != Target.CHECKSUM THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					Target.changed_at	=	Source.changed_at

				,	Target.mandant	=	Source.mandant
				,	Target.wilken_mnd_id	=	Source.wilken_mnd_id
				,	Target.wilken_konzern	=	Source.wilken_konzern
				,	Target.wilken_gpmandant	=	Source.wilken_gpmandant


	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_mandant]
			,[mandant]
			,[wilken_mnd_id]
			,[wilken_konzern]
			,[wilken_gpmandant]
			,created_at
			,[changed_at]
		)
		VALUES (
				Source.[id_mandant]
			,	Source.[mandant]
			,	Source.[wilken_mnd_id]
			,	Source.[wilken_konzern]
			,	Source.[wilken_gpmandant]
			,	Source.created_at
			,	Source.[changed_at]
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
