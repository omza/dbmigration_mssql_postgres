-- Object: core.load_messpunkte_powerswitch_sagamfg
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Create date: 12.03.2025
-- Description:	
	
	lädt die messpunkte aus nedi / powerswitch datenbank für die SAGA mfgs
		core.messpunkte
	

-- Change Log

	12.03.2025	OME initial
	26.03.2025	OMe	Geräteart 301 und Gerätetyp neu schlüsseln
	


-- Test:

	exec core.[load_messpunkte_powerswitch_sagamfg] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_messpunkte_powerswitch_sagamfg]
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
		Pflege core.messpunkte
	*/
	;WITH TargetRows AS 
	(
		----- ZIEL -----

		SELECT 
			[id_mandant]
			,[id_energieart]
			,[id_geraeteart]
			,[id_geraetetyp]
			,[id_quellsystem]
			,[messpunkt_ident]
			,[messpunkt_serialnummer]
			,[messpunkt_name]
			,[messpunkt_beschreibung]
			,[location_beschreibung]
			,[location_lat]
			,[location_lon]
			,[created_at]
			,[changed_at]
			,CHECKSUM(
				[id_mandant]
				,[id_energieart]
				,[id_geraeteart]
				,ISNULL([id_geraetetyp],'')
				,[messpunkt_serialnummer]
				,[messpunkt_name]
				,[messpunkt_beschreibung]
				,[location_beschreibung]
				,[location_lat]
				,[location_lon]
			) as CHECKSUM
		FROM [EnergyDWH].[core].[messpunkte]
		AS	Dim


	), tannis_mfg as (

		SELECT
			MAX(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(UPPER(adr.STREET + adr.HOUSENO + adr.HOUSENO_SUPPL),'ß','SS'),'STRASSE',''),'STR',''),'.',''),'-',''), ' ' , '')) as location,
			STANDORT_KURZNAME,
			REPLACE(STANDORT_KURZNAME,'MFGSA','') as mfg_saga_id,
			STANDORT_NAME,
			STANDORT_ADRESSE,
			max(GEO_X) location_lat, 
			max(GEO_Y) as location_lon, 
			max(POP) pop, 
			max(GESELLSCHAFT) gesellschaft 
		from
			RealDWH.stage.[TANNIS_SOAP_MFG] mfg with (nolock)
		join
			RealDWH.dwh.DIM_ADRESSE adr with (nolock) on mfg.STANDORT_ADRESSE = adr.TANNISADDRESS_ID
		group by
			STANDORT_KURZNAME,
			STANDORT_NAME,
			STANDORT_ADRESSE

	), nedi_mfg_pwr as (

		select 
			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(UPPER(ndev.location),'SAGA',''),'MFG',''),'ß','SS'),'STRASSE',''),'STR',''),'.',''),'-',''), ' ','') as location,
			ndev.device,
			ndev.serial,
			ndev.location as org_location,
			ndev.devgroup as pop,
			pwr.type,
			ndev.description,
			max(CASE WHEN
				CHARINDEX('MFG',ndev2.description)>0 
				THEN SUBSTRING(ndev2.description, CHARINDEX('MFG',ndev2.description)+4,4)
				ELSE '' END) mfg_saga_id
		from 
			raw.power_switch_list_eltek_saga pwr
		join
			[raw].[nedi_devices] ndev on pwr.device = ndev.device 
		left join
			[raw].[nedi_devices] ndev2 on pwr.device <> ndev2.device and ndev2.location = pwr.location
		group by
			ndev.device,
			ndev.serial,
			ndev.location,
			ndev.devgroup,
			pwr.type,
			ndev.description
	)

	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		select
			2 id_mandant,
			1 id_energieart,
			301 id_geraeteart,
			typ.id_geraetetyp,
			3 id_quellsystem,
			LTRIM(RTRIM(ndev.device)) as messpunkt_ident,
			LEFT(ndev.serial,50) as messpunkt_serialnummer,
			LEFT(ndev.org_location,50) as messpunkt_name,
			LEFT(ndev.description,50) as messpunkt_beschreibung,
			LEFT(ndev.pop + '-' + ISNULL(tannis.STANDORT_NAME,tannis2.STANDORT_NAME),100) as location_beschreibung,
			TRY_CAST(ISNULL(tannis.location_lat,tannis2.location_lat) as DECIMAL(10,8)) as location_lat,
			TRY_CAST(ISNULL(tannis.location_lon,tannis2.location_lon) as DECIMAL(10,8)) as location_lon,
			CHECKSUM(
				2
				,1
				,301
				,ISNULL(typ.id_geraetetyp,'')
				,LEFT(ndev.serial,50)
				,LEFT(ndev.org_location,50)
				,LEFT(ndev.description,50)
				,LEFT(ndev.pop + '-' + ISNULL(tannis.STANDORT_NAME,tannis2.STANDORT_NAME),100)
				,TRY_CAST(ISNULL(tannis.location_lat,tannis2.location_lat) as DECIMAL(10,8))
				,TRY_CAST(ISNULL(tannis.location_lon,tannis2.location_lon) as DECIMAL(10,8))
			) as CHECKSUM
		from 
			nedi_mfg_pwr ndev 
		left join 
			tannis_mfg tannis on ndev.location = tannis.location 
		left join
			tannis_mfg tannis2 on ndev.mfg_saga_id = tannis2.mfg_saga_id
		left join
			core.geraetetypen typ on ndev.type = typ.[quellsystem_ident] and typ.id_quellsystem = 3

		----- QUELLE -----
	)
	AS Source	ON	 Source.id_quellsystem = Target.id_quellsystem and Source.messpunkt_ident = Target.messpunkt_ident

	WHEN MATCHED AND Source.CHECKSUM != Target.CHECKSUM THEN

		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
				Target.changed_at	=	GETDATE()
			,	Target.[id_energieart]	=	Source.[id_energieart]
			,	Target.id_mandant	=	Source.id_mandant

			,	Target.[id_geraeteart]	=	Source.[id_geraeteart]
			,	Target.[id_geraetetyp]	=	Source.[id_geraetetyp]

			,	Target.[messpunkt_serialnummer]	=	Source.[messpunkt_serialnummer]

			,	Target.[messpunkt_name]	=	Source.[messpunkt_name]
			,	Target.[messpunkt_beschreibung]	=	Source.[messpunkt_beschreibung]
			,	Target.[location_beschreibung]	=	Source.[location_beschreibung]

			,	Target.[location_lat]	=	Source.[location_lat]
			,	Target.[location_lon]	=	Source.[location_lon]



	WHEN NOT MATCHED BY TARGET THEN

		----- INSERT, weil noch nicht vorhanden -----


		INSERT (
			[id_mandant]
			,[id_energieart]
			,[id_geraeteart]
			,[id_geraetetyp]
			,[id_quellsystem]
			,[messpunkt_ident]
			,[messpunkt_serialnummer]
			,[messpunkt_name]
			,[messpunkt_beschreibung]
			,[location_beschreibung]
			,[location_lat]
			,[location_lon]
		)
		VALUES (
			Source.[id_mandant]
			,	Source.[id_energieart]
			,	Source.[id_geraeteart]
			,	Source.[id_geraetetyp]
			,	Source.[id_quellsystem]
			,	Source.[messpunkt_ident]
			,	Source.[messpunkt_serialnummer]
			,	Source.[messpunkt_name]

			,	Source.[messpunkt_beschreibung]
			,	Source.[location_beschreibung]
			,	Source.[location_lat]
			,	Source.[location_lon]

		)

	;
	
	
	/*
		Pflege core.messpunkt_attribute
	*/	
	
	
	WITH TargetRows AS 
	(
		----- ZIEL -----
	SELECT 
		[id_messpunkt]
      ,[id_messpunkt_attribut]
      ,[wert]
      ,[created_at]
      ,[changed_at]
	FROM 
		[core].[messpunkt_attribute]	AS	Dim
	where 
		[id_messpunkt_attribut] = 1 -- pop_id



	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		SELECT
			mp.id_messpunkt,
			1 as [id_messpunkt_attribut], --id_pop
			Substring(ndev.devgroup, PATINDEX('%[0-9]%',ndev.devgroup), Len(ndev.devgroup)) as wert
		FROM
			[core].[messpunkte] mp
		join
			raw.power_switch_list_eltek_saga mfg on mp.messpunkt_ident = mfg.device
		join
			raw.nedi_devices ndev on mfg.device = ndev.device
		WHERE
			mp.id_quellsystem = 3
		----- QUELLE -----
	)
	AS Source	ON		Source.id_messpunkt = Target.id_messpunkt and Source.[id_messpunkt_attribut] = Target.[id_messpunkt_attribut]

	WHEN MATCHED AND Source.wert != Target.wert THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					Target.changed_at	=	GETDATE()
				,	Target.wert	=	Source.wert


	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_messpunkt]
		  ,[id_messpunkt_attribut]
		  ,[wert]
		)
		VALUES (
				Source.id_messpunkt
			,	Source.[id_messpunkt_attribut]
			,	Source.wert
		)

	;

	/*
		Pflege core.messpunkt_attribute  id_mfg_saga
	*/	
	
	
	WITH TargetRows AS 
	(
		----- ZIEL -----
	SELECT 
		[id_messpunkt]
      ,[id_messpunkt_attribut]
      ,[wert]
      ,[created_at]
      ,[changed_at]
	FROM 
		[core].[messpunkt_attribute]	AS	Dim
	where 
		[id_messpunkt_attribut] = 2 --id_mfg_saga


	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		SELECT
			mp.id_messpunkt,
			2 as [id_messpunkt_attribut], --id_mfg_saga
			SUBSTRING([location_beschreibung], (CHARINDEX('-SA',[location_beschreibung])+3), 4) wert
		FROM
			[core].[messpunkte] mp
		join
			raw.power_switch_list_eltek_saga mfg on mp.messpunkt_ident = mfg.device
		WHERE
			mp.id_quellsystem = 3 and
			CHARINDEX('-SA',[location_beschreibung])> 0 and
			isnumeric(SUBSTRING([location_beschreibung], (CHARINDEX('-SA',[location_beschreibung])+3), 4)) = 1
		----- QUELLE -----
	)
	AS Source	ON		Source.id_messpunkt = Target.id_messpunkt and Source.[id_messpunkt_attribut] = Target.[id_messpunkt_attribut]

	WHEN MATCHED AND Source.wert != Target.wert THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					Target.changed_at	=	GETDATE()
				,	Target.wert	=	Source.wert


	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_messpunkt]
		  ,[id_messpunkt_attribut]
		  ,[wert]
		)
		VALUES (
				Source.id_messpunkt
			,	Source.[id_messpunkt_attribut]
			,	Source.wert
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
