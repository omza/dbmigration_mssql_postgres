-- Object: core.load_messpunkte_elementiot_wasserzaehler
-- Type  : SQL_STORED_PROCEDURE







/* =============================================
	
	lädt die messpunkte aus element iot 
		core.messpunkte
		core.messpunkte_attribute

-- Change Log

	21.10.2025	OME initial
	


-- Test:

	exec core.[load_messpunkte_elementiot_wasserzaehler] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_messpunkte_elementiot_wasserzaehler]
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

	declare 
		@id_quellsystem int = 2 -- element iot

	declare @parser_id table (parser_id varchar(36))
	insert into @parser_id (parser_id) values ('a30b97a8-8372-4650-80d7-e6c3f3449ef6')


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
				,isnull([location_beschreibung],'')
				,[location_lat]
				,[location_lon]
			) as CHECKSUM
		FROM [EnergyDWH].[core].[messpunkte]
		WHERE id_quellsystem = @id_quellsystem

	), 
	
	element as (

		SELECT  
				e.[id] as [messpunkt_ident]
				,right(e.name,len(e.name)-charindex('-',e.name)) as [messpunkt_serialnummer]
				,e.[name] as [messpunkt_name]
				,left(e.fields,50) [messpunkt_beschreibung]
				,null [location_beschreibung]
				,try_cast(e.lat as decimal(10,8)) as [location_lat]
				,try_cast(e.lon as decimal(10,8)) as [location_lon]
				,convert(datetime,left(e.inserted_at,23),126) as created_at
				,convert(datetime,left(e.updated_at,23),126)  as [changed_at]
				
		  FROM 
			[EnergyDWH].[raw].[element_iot_devices] e
		 where
			parser_id in (select parser_id from @parser_id)
			and charindex('-',e.name) > 0
	), 
	
	messpunkte as (

		SELECT 
				ROW_NUMBER() over (partition by messpunkt_ident order by zae.ZAE_ENERGIEART) doublette
				,1 [id_mandant]
				,cast(zae.ZAE_ENERGIEART as int) as [id_energieart] -- wasser und warmwasser
				,1 [id_geraeteart]
				,ztp.[id_geraetetyp]
				,@id_quellsystem as [id_quellsystem]
				,[messpunkt_ident]
				,[messpunkt_serialnummer]
				,[messpunkt_name]
				,[messpunkt_beschreibung]
				,null [location_beschreibung]
				,[location_lat]
				,[location_lon]
				,e.created_at
				,e.changed_at
				,CHECKSUM(
					1
					,cast(zae.ZAE_ENERGIEART as int)
					,1
					,ISNULL([id_geraetetyp],'')
					,[messpunkt_serialnummer]
					,[messpunkt_name]
					,[messpunkt_beschreibung]
					,isnull([location_beschreibung],'')
					,[location_lat]
					,[location_lon]
				) as CHECKSUM
		  FROM 
			element e
		join
			raw.wilken_enzaehler zae on e.[messpunkt_serialnummer] = zae.ZAE_NR and zae.MND_ID = 1
		join
			core.geraetetypen ztp on zae.ZTP_NR = ztp.quellsystem_ident and zae.MND_ID = ztp.id_mandant and ztp.id_quellsystem = 1 -- wilken

	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----

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
			,[CHECKSUM]
		FROM
			messpunkte
		where
			doublette = 1 
			-- Wasser Zähler sind vereinzelt in Wasser und Warmwasser Energieart zugeornet - 
			--Es handelt sich aber um den selben Zähler deshalb nur einmal anlegen gleicher Messwert wird mit Warmwasserobis dazu angelegt
		----- QUELLE -----
	)
	AS Source	ON	 Source.id_quellsystem = Target.id_quellsystem and Source.messpunkt_ident = Target.messpunkt_ident

	WHEN MATCHED AND Source.CHECKSUM != Target.CHECKSUM THEN

		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
				Target.changed_at	=	getdate()
			,	Target.created_at	= Source.created_at
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
			,created_at
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
			,	Source.created_at
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
			[id_messpunkt_attribut] between 6 and 11 
	),

	stage_attribute as (

		select 
			mp.id_messpunkt,
			e.parser_id,
			left(ltrim(rtrim(replace(replace(replace(e.slugs,'"',''),'[' ,''),']' ,''))),200) as tags,
			e.avg_sf as sf,
			e.avg_rssi as rssi,
			e.avg_snr as snr,
			e.secs as msg_interval_secs
		from 
			core.messpunkte mp
		join
			raw.element_iot_devices e 
		on 
			e.id = mp.messpunkt_ident
			and mp.id_quellsystem = @id_quellsystem
			and	e.parser_id in (select parser_id from @parser_id)
			and charindex('-',e.name) > 0
	), 

	attribute as (

		select
			id_messpunkt,
			6 as id_messpunkt_attribut,
			parser_id as wert
		from
			stage_attribute
		union
		select
			id_messpunkt,
			7 as id_messpunkt_attribut,
			tags as wert
		from
			stage_attribute
		union
		select
			id_messpunkt,
			8 as id_messpunkt_attribut,
			sf as wert
		from
			stage_attribute
		union
		select
			id_messpunkt,
			9 as id_messpunkt_attribut,
			rssi as wert
		from
			stage_attribute
		union
		select
			id_messpunkt,
			10 as id_messpunkt_attribut,
			snr as wert
		from
			stage_attribute
		union
		select
			id_messpunkt,
			11 as id_messpunkt_attribut,
			msg_interval_secs as wert
		from
			stage_attribute
	)

	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		SELECT
			id_messpunkt,
			id_messpunkt_attribut,
			wert
		FROM
			attribute
		where
			wert is not null

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
