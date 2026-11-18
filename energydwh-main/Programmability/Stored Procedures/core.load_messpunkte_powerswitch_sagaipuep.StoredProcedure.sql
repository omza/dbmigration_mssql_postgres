-- Object: core.load_messpunkte_powerswitch_sagaipuep
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Create date: 13.03.2025
-- Description:	
	
	lädt die messpunkte aus nedi / powerswitch datenbank für die SAGA mfgs
		core.messpunkte
	

-- Change Log

	13.03.2025	OME initial
	26.03.2025	OMe	Geräteart 302 und Gerätetyp neu schlüsseln	
	15.07.2025	OMe	Distinct clause 
	04.11.2026	OMe	Umstellung auf nedi Datenbank


-- Test:

	exec core.[load_messpunkte_powerswitch_sagaipuep] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_messpunkte_powerswitch_sagaipuep]
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
				,ISNULL(cast([location_lat] as nvarchar),'')
				,ISNULL(cast([location_lon] as nvarchar),'')
			) as CHECKSUM
		FROM [EnergyDWH].[core].[messpunkte]
		
		AS	Dim
		where id_quellsystem = 3


	)

	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		select distinct
			2 id_mandant,
			1 id_energieart,
			302 id_geraeteart,
			typ.id_geraetetyp,
			3 id_quellsystem,
			messpunkt_ident,
			messpunkt_serialnummer,
			messpunkt_name,
			messpunkt_beschreibung,
			location_beschreibung,
			case when charindex(',', lat_lon) > 1 then 
				case when isnumeric(left(lat_lon, charindex(',', lat_lon)-1)) = 1 then 	try_cast(left(lat_lon, charindex(',', lat_lon)-1) as decimal(10,8)) else NULL end
			else NULL end location_lat,

			case when charindex(',', lat_lon) > 1 then 
				case when isnumeric(ltrim(rtrim(right(lat_lon,len(lat_lon)-charindex(',', lat_lon))))) = 1 then try_cast(ltrim(rtrim(right(lat_lon,len(lat_lon)-charindex(',', lat_lon)))) as decimal(10,8)) else NULL end
			else NULL end location_lon,
			
			CHECKSUM(
				2
				,1
				,302
				,ISNULL(typ.id_geraetetyp,'')
				,messpunkt_serialnummer
				,messpunkt_name
				,messpunkt_beschreibung
				,location_beschreibung
				,case when charindex(',', lat_lon) > 1 then 
					left(lat_lon, charindex(',', lat_lon)-1) 
				else NULL end
				,case when charindex(',', lat_lon) > 1 then 
					right(lat_lon, charindex(',', lat_lon)-1)
				else NULL end
			) as CHECKSUM
		from 
			[stage].[nedi_ipueps_saga_power] ndev
		left join
			core.geraetetypen typ on ndev.switch_type = typ.[quellsystem_ident] and typ.id_quellsystem = 3

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
			raw.nedi_devices ndev on mp.messpunkt_ident = ndev.device
		WHERE
			mp.id_quellsystem = 3
			and mp.id_geraeteart = 302

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
