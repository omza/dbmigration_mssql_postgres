-- Object: core.load_argos_messpunkte_und_werte
-- Type  : SQL_STORED_PROCEDURE





/* =============================================
-- Author:		Oliver Meyer
-- Create date: 25.04.2025
-- Description:	
	
	lädt die messpunkte und die messwerte aus argos ZFA
		core.messpunkte
		core.messwerte
	

-- Change Log

	25.04.2025	OME initial
	29.04.2025	OME	Zeitumstellung SW mit bStunde
	29.10.2025	OME Fix Zeitumstellung b stunde
	12.11.2025	OME	Messpuntke OHNE Zählpunkt ausschliessen
	18.02.2026	OME	fix pk_messwerte violation


-- Test:

	exec core.[load_argos_messpunkte_und_werte] -1,  0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_argos_messpunkte_und_werte]
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

		DECLARE 
			@id_quellsystem int = 4 -- argos


		-- Ermittle Messpunkte mit Attributen in temporäre Tabelle (aus der jeweils letzten Datei) 
		IF OBJECT_ID('tempdb..#argos_files_tmp') IS NOT NULL DROP TABLE #argos_files_tmp
		IF OBJECT_ID('tempdb..#argos_messpunkte_tmp') IS NOT NULL DROP TABLE #argos_messpunkte_tmp

		-- speichere die filekopfdaten zwischen
		select
			ROW_NUMBER() OVER (partition by Meteringcode order by Zeitraum desc) AS ROW#
			,row_number() over (partition by Meteringcode,Zeitraum, OBIS order by load_log_id) as reihenfolge
			,[load_log_id]
			,[filename]
			,[Kunden_Name]
			,[Kunden_Nummer]
			,[Meteringcode]
			,[Zaehlernummer]
			,[Kanal]
			,[OBIS]
			,[Zeitraum]
			,[tag]
			,[id_typtag]
			,[id_zeitumstellung]
			,[Wandlerfaktor]
			,[Raster_Minuten]
			,Isnull([Messeinheit], o.obis_einheit) as [Messeinheit]
			,[Anzahl_Werte]
			,[kWh]
			,o.id_obis
		into
			#argos_files_tmp
		from
			stage.argos_file_kopf k
		join
			core.obis o on k.OBIS = o.obis_kennziffer
		where
			k.Meteringcode is not null
		


		-- Eine Verarbeitung von Folgewerten erfolgt erst im nächsten Lauf
		-- keine Verarbeitung von Sommer/Winterzeitumstellungen
		delete from #argos_files_tmp where reihenfolge > 1

		;with argos as (

			select distinct
		
				i.Meteringcode as messpunkt_ident,
				i.Zaehlernummer  as messpunkt_name,
				ltrim(rtrim(replace(i.Kunden_Nummer + ';'+ i.Kunden_Name  ,',',''))) as messpunkt_beschreibung,
				--i.Kanal,
				case 
					when LEFT(OBIS,1) = 1 then 1 
					when LEFT(OBIS,1) = 7 then 2
					else null
				end as id_energieart,
				--i.Zeitraum as tag,
				zp.ZPT_ID as id_zp,
				zpg.ZPG_STATUS,
				zpg.ZAE_ID,
				i.Wandlerfaktor
			from 
				#argos_files_tmp i
			left join
				raw.wilken_enzpt zp on i.Meteringcode = zp.ZPT_METERINGCODE
			left join
				raw.wilken_enzptgeraet zpg 
			on 
				zp.ZPT_ID = zpg.ZPT_ID 
				and i.Zeitraum between cast(zpg.ZPG_EINBAUDATUM as date) and cast(isnull(zpg.ZPG_AUSBAUDATUM,'9999-12-31') as date)
				--and ZPG_STATUS = 1
			where
				i.ROW# = 1

		), geraete as (
	
			select
				z.ZAE_ID,
				z.ZAE_IDENTNR,
				z.ZAE_NR,
				z.ZAE_SERIALNR,
				z.MND_ID as id_mandant,
				z.GER_ID as id_geraeteart,
				z.ZAE_ENERGIEART as id_energieart,
				t.id_geraetetyp,
				t.geraetetyp
			from
				raw.wilken_enzaehler z
			join
				core.geraetetypen t on z.ZTP_NR = t.quellsystem_ident

		)

		select 
			isnull(max(isnull(g1.id_mandant,isnull(g2.id_mandant,isnull(g3.id_mandant,g4.id_mandant)))),1) as id_mandant,
			a.id_energieart,
			max(isnull(g1.id_geraeteart, isnull(g2.id_geraeteart, isnull(g3.id_geraeteart, g4.id_geraeteart)))) as id_geraeteart,
			max(isnull(g1.id_geraetetyp, isnull(g2.id_geraetetyp, isnull(g3.id_geraetetyp, g4.id_geraetetyp)))) as id_geraetetyp,
			4 as id_quellsystem,
			a.messpunkt_ident,
			a.messpunkt_name,
			max(a.messpunkt_beschreibung) as messpunkt_beschreibung,
			max(isnull(g1.ZAE_ID, isnull(g2.ZAE_ID, isnull(g3.ZAE_ID, g4.ZAE_ID)))) as wilken_zae_id,
			a.id_zp,
			a.Wandlerfaktor
		into 
			#argos_messpunkte_tmp
		from 
			argos a
		left join
			geraete g1 on a.ZAE_ID = g1.ZAE_ID and a.messpunkt_name = g1.ZAE_NR
		left join
			geraete g2 on a.ZAE_ID = g2.ZAE_ID and a.messpunkt_name = g2.ZAE_SERIALNR
		left join
			geraete g3 on a.ZAE_ID = g3.ZAE_ID and charindex(g3.ZAE_NR,a.messpunkt_name) > 0
		left join
			geraete g4 on a.ZAE_ID = g4.ZAE_ID and charindex(a.messpunkt_name, g4.ZAE_NR) > 0
		group by
			a.id_energieart,
			a.messpunkt_ident,
			a.messpunkt_name,
			a.id_zp,
			a.wandlerfaktor
		




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
				,[messpunkt_name]
				,[messpunkt_beschreibung]
				,[created_at]
				,[changed_at]
				,CHECKSUM(
					[id_mandant]
					,[id_energieart]
					,isnull([id_geraeteart],0)
					,ISNULL([id_geraetetyp],0)
					,[messpunkt_name]
					,isnull([messpunkt_beschreibung],'')
				) as CHECKSUM
			FROM [core].[messpunkte]
			AS	Dim


		)

		MERGE INTO TargetRows	AS	Target
		USING
		(
			----- QUELLE -----

			select 
				id_mandant,
				a.id_energieart,
				id_geraeteart,
				id_geraetetyp,
				@id_quellsystem as id_quellsystem,
				a.messpunkt_ident,
				a.messpunkt_name,
				messpunkt_beschreibung,
				CHECKSUM(
					id_mandant
					,a.id_energieart
					,isnull(id_geraeteart,0)
					,ISNULL(id_geraetetyp,0)
					,a.messpunkt_name
					,isnull(messpunkt_beschreibung,'')
				) as CHECKSUM
			from 
				#argos_messpunkte_tmp a

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

				,	Target.[messpunkt_name]	=	Source.[messpunkt_name]
				,	Target.[messpunkt_beschreibung]	=	Source.[messpunkt_beschreibung]


		WHEN NOT MATCHED BY TARGET THEN

			----- INSERT, weil noch nicht vorhanden -----


			INSERT (
				[id_mandant]
				,[id_energieart]
				,[id_geraeteart]
				,[id_geraetetyp]
				,[id_quellsystem]
				,[messpunkt_ident]
				,[messpunkt_name]
				,[messpunkt_beschreibung]
			)
			VALUES (
				Source.[id_mandant]
				,	Source.[id_energieart]
				,	Source.[id_geraeteart]
				,	Source.[id_geraetetyp]
				,	Source.[id_quellsystem]
				,	Source.[messpunkt_ident]
				,	Source.[messpunkt_name]
				,	Source.[messpunkt_beschreibung]

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
				[id_messpunkt_attribut] in  (3,4,5) -- pop_id



		)
		MERGE INTO TargetRows	AS	Target
		USING
		(
			----- QUELLE -----
			select
				mp.id_messpunkt,
				3 as [id_messpunkt_attribut], --wandlerfaktor
				wandlerfaktor as wert
			from
				[core].[messpunkte] mp
			join
				#argos_messpunkte_tmp att on mp.messpunkt_ident = att.messpunkt_ident 
			where
				att.wandlerfaktor is not null
				and mp.id_quellsystem = @id_quellsystem
			union
			select
				mp.id_messpunkt,
				4 as [id_messpunkt_attribut], --id_zp
				att.id_zp as wert
			from
				[core].[messpunkte] mp
			join
				#argos_messpunkte_tmp att on mp.messpunkt_ident = att.messpunkt_ident
			where
				att.id_zp is not null
				and mp.id_quellsystem = @id_quellsystem
			union
			select
				mp.id_messpunkt,
				5 as [id_messpunkt_attribut], --wilken_zae_id
				att.wilken_zae_id as wert
			from
				[core].[messpunkte] mp
			join
				#argos_messpunkte_tmp att on mp.messpunkt_ident = att.messpunkt_ident
			where
				att.wilken_zae_id is not null
				and mp.id_quellsystem = @id_quellsystem

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
			core.messwerte

	*/
		-- Merge Messwerte in tabelle
		--------------------------------------------------------------------------------------------------------------------------
		MERGE INTO [core].[messwerte] AS Target
		USING
		(
			----- QUELLE -----
			select distinct
				mp.[id_messpunkt]
				,[id_obis]
				,[messung_am]
				,case 
					when isnull(w.wert_reihenfolge,1) = 2 then 'b'
					when isnull(w.wert_reihenfolge,1) = 3 then 'c' 
					else '' 
				end as bstunde
				,w.[tag]
				,w.[id_typtag]
				,k.[id_zeitumstellung]
				,[messwert]
				,[messeinheit]
				,[id_wertstatus]
			from
				#argos_files_tmp k
			join
				stage.argos_file_werte w on k.filename = w.filename
			left join
				core.messpunkte mp on k.Meteringcode = mp.messpunkt_ident and mp.id_quellsystem = @id_quellsystem
			left join
				core.wertstatus s on w.argos_wertstatus = s.argos_wertstatus

			----- QUELLE -----

		)	AS Source	
						ON		
								Source.id_messpunkt = Target.id_messpunkt 
							and Source.[id_obis] = Target.[id_obis]
							and Source.[messung_am] = Target.[messung_am]
							and Source.[bstunde] = Target.[bstunde]

		WHEN MATCHED AND (Source.[messwert] != Target.[messwert] OR Source.[messeinheit] != Target.[messeinheit]) THEN

			----- UPDATE, weil schon vorhanden -----
			UPDATE	SET 
						Target.changed_at	=	GETDATE()
					,	Target.messwert	=	Source.messwert
					,	Target.id_version = Target.id_version + 1
					,	Target.messeinheit = Source.messeinheit
					,	Target.id_wertstatus = Source.[id_wertstatus]
					,   Target.neu_flag = 1
					,	Target.tag = Source.tag
					,	Target.[id_typtag] = Source.[id_typtag]
					,	Target.[id_zeitumstellung] = Source.[id_zeitumstellung]


		WHEN NOT MATCHED BY TARGET THEN
			----- INSERT, weil noch nicht vorhanden -----
			INSERT (
				[id_messpunkt]
				,[id_obis]
				,[messung_am]
				,bstunde
				,[tag]
				,[id_typtag]
				,[id_zeitumstellung]
				,[id_version]
				,[messwert]
				,[messeinheit]
				,[id_wertstatus]
				,[neu_flag]
			)
			VALUES (
				Source.[id_messpunkt]
				,Source.[id_obis]
				,Source.[messung_am]
				,Source.bstunde
				,Source.[tag]
				,Source.[id_typtag]
				,Source.[id_zeitumstellung]
				,1
				,Source.[messwert]
				,Source.[messeinheit]
				,Source.[id_wertstatus] 
				,1
			);


		-- delete from raw table
		delete from raw.argos_lastgang
		where filename in (select filename from #argos_files_tmp)


		-- Housekeeping
		IF OBJECT_ID('tempdb..#argos_files_tmp') IS NOT NULL DROP TABLE #argos_files_tmp
		IF OBJECT_ID('tempdb..#argos_messpunkte_tmp') IS NOT NULL DROP TABLE #argos_messpunkte_tmp


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
