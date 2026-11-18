-- Object: core.load_obis
-- Type  : SQL_STORED_PROCEDURE
/* =============================================
-- Author:		Oliver Meyer
-- Create date: 14.11.2024
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.obis 
	

-- Change Log

	04.02.2025	OME initial
	


-- Test:

	exec core.load_obis -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	core.load_obis
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

	WITH TargetRows AS 
	(
		----- ZIEL -----
		SELECT [id_obis]
			  ,[obis_kennziffer]
			  ,[obis_einheit]
			  ,[obis_beschreibung]
			  ,[id_energieart]
			  ,obis_energierichtung
			  ,[obis_medium]
			  ,[obis_kanal]
			  ,[obis_messgroesse]
			  ,[obis_messart]
			  ,[obis_tarifstufe]
			  ,changed_at
			  ,CHECKSUM(
					[obis_kennziffer]
				  ,[obis_einheit]
				  ,[obis_beschreibung]
				  ,[id_energieart]
				  ,obis_energierichtung
				  ,[obis_medium]
				  ,[obis_kanal]
				  ,[obis_messgroesse]
				  ,[obis_messart]
				  ,[obis_tarifstufe]) AS CHECKSUM
		  FROM [EnergyDWH].[core].[obis]	AS	Dim


	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		select distinct
			CAST((OBS_MEDIUM + REPLACE(OBS_KANAL,'b','1') + OBS_MESSGROESSE + OBS_MESSART + OBS_TARIFSTUFE) as INT) as id_obis,
			REPLACE(OBS_BEZEICHNUNG, 'b', '1') AS obis_kennziffer,
			OBS_EINHEIT as obis_einheit,
			OBS_OBIS_BESCHREIBUNG as obis_beschreibung,
			CAST(ena.ENA_NR as int) as id_energieart,
			CAST(OBS_ENERGIERICHTUNG as int) as obis_energierichtung,
			CAST(OBS_MEDIUM as int) as obis_medium,
			CAST(REPLACE(OBS_KANAL,'b','1') as int) as obis_kanal,
			CAST(OBS_MESSGROESSE as int) as obis_messgroesse,
			cast(OBS_MESSART as int) as obis_messart,
			cast(OBS_TARIFSTUFE as int) as obis_tarifstufe,
			CHECKSUM(
				REPLACE(OBS_BEZEICHNUNG, 'b', '1') ,
				OBS_EINHEIT ,
				OBS_OBIS_BESCHREIBUNG ,
				CAST(ena.ENA_NR as int),
				CAST(OBS_ENERGIERICHTUNG as int),
				CAST(OBS_MEDIUM as int),
				CAST(REPLACE(OBS_KANAL,'b','1') as int) ,
				CAST(OBS_MESSGROESSE as int) ,
				cast(OBS_MESSART as int) ,
				cast(OBS_TARIFSTUFE as int) 
			) AS CHECKSUM
		from
			raw.wilken_enobis obis
		join
			raw.wilken_crena ena on obis.ENA_ID = ena.ENA_ID
		where
			OBS_EINHEIT IS NOT NULL
			and OBS_EINHEIT <> '€'
			and OBS_OPTIONAL = 0
		----- QUELLE -----
	)
	AS Source	ON		Source.id_obis = Target.id_obis

	WHEN MATCHED AND Source.[CHECKSUM] != Target.[CHECKSUM] THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					Target.changed_at							=	GETDATE()
				,	Target.[obis_kennziffer]				=	Source.[obis_kennziffer]
				,	Target.[obis_einheit]					=	Source.[obis_einheit]
				,	Target.[obis_beschreibung]					=	Source.[obis_beschreibung]
				,	Target.id_energieart					=	Source.id_energieart
				,	Target.obis_energierichtung					=	Source.obis_energierichtung
				,	Target.[obis_medium]				=	Source.[obis_medium]
				,	Target.[obis_kanal]					=	Source.[obis_kanal]
				,	Target.[obis_messgroesse]					=	Source.[obis_messgroesse]	
				,	Target.[obis_messart]					=	Source.[obis_messart]
				,	Target.[obis_tarifstufe]					=	Source.[obis_tarifstufe]	

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_obis]
           ,[obis_kennziffer]
           ,[obis_einheit]
           ,[obis_beschreibung]
		   ,id_energieart
		   ,obis_energierichtung
           ,[obis_medium]
           ,[obis_kanal]
           ,[obis_messgroesse]
           ,[obis_messart]
           ,[obis_tarifstufe]
		)
		VALUES (
				Source.id_obis
			,	Source.[obis_kennziffer]
			,	Source.[obis_einheit]
			,	Source.[obis_beschreibung]
			,	Source.id_energieart
			,	Source.obis_energierichtung
			,	Source.[obis_medium]
			,	Source.[obis_kanal]
			,	Source.[obis_messgroesse]
			,	Source.[obis_messart]
			,	Source.[obis_tarifstufe]
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
