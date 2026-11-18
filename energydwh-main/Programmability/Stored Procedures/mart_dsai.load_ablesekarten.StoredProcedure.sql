-- Object: mart_dsai.load_ablesekarten
-- Type  : SQL_STORED_PROCEDURE



/* =============================================
-- Author:		Oliver Meyer
-- Create date: 15.12.2025
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: mart_dsai.Ablesekarten 
	

-- Change Log

	15.12.2025	OME initial
	02.07.2026	OME	fix doublette (991697, 1SAG2024041194, 1-0:2.8.0)
	


-- Test:

	exec mart_dsai.load_ablesekarten -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[mart_dsai].[load_ablesekarten]
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
		
		-- alter stand in tmp tabelle auslagern
		IF OBJECT_ID(N'tempdb..#tmp_ablesekarten') IS NOT NULL
			drop table #tmp_ablesekarten

		select * into #tmp_ablesekarten from mart_dsai.Ablesekarten

		-- tabelle löschen
		truncate table mart_dsai.Ablesekarten;

		-- tabelle neu befüllen

		with geraete as (

			select
				lzpg.ZPT_ID id_zp,
				try_cast(lzpg.MND_ID as int) id_mandant,
				lzpg.ZAE_ID id_zaehler,
				try_convert(date,lzpg.ZPG_EINBAUDATUM,120) einbaudatum,
				lzpg.ZPG_ZAE_NR zaehlernummer,
				lzpg.ZPG_ID
			from
				raw.wilken_enzptgeraet lzpg
			where
				lzpg.ZPG_STATUS <> 9
				and ZPG_ZAE_NR is not null
				and ZPG_AUSBAUDATUM is null
		
		), zaehlerstaende as (

			SELECT 
			  [ZPZ_ID]
			  ,[ZPS_BEGINN]
			  ,[ZPS_ENDE]
			  ,[ZPS_STANDBEGINN]
			  ,[ZPS_STANDENDE]
			  ,[ZPS_ABLESEDATUM]
			  ,row_number() over (partition by ZPZ_ID order by ZPS_ENDE desc) as reihenfolge
			FROM [EnergyDWH].[raw].[wilken_enzpzstand]

		), zaehlwerkstand as (

			select
				zs.[ZPZ_ID],
				zw.[ZPG_ID],
				zw.[ZPZ_OBISCODE] as obis,
				try_convert(date,zs.ZPS_ABLESEDATUM, 120) ablesedatum,
				zs.ZPS_STANDENDE zaehlerstand
			from
				raw.wilken_enzaehlpunktzaehlwerke zw
			left join
				zaehlerstaende zs on zw.ZPZ_ID = zs.ZPZ_ID and zs.reihenfolge = 1
			where
				getdate() between zw.ZPZ_BEGINN and isnull(zw.ZPZ_ENDE, GETDATE())
		)
		insert into [mart_dsai].[Ablesekarten]
           ([Kundennummer]
           ,[Geschaeftspartner]
           ,[Geschaeftspartner2]
           ,[Geschaeftspartner_Zusatz]
           ,[Anrede]
           ,[id_person]
           ,[Vorname]
           ,[Nachname]
           ,[telefonnummer]
           ,[mobilnummer]
           ,[faxnummer]
           ,[email]
           ,[Energieart]
           ,[Abnahmestelle]
           ,[Zaehlernummer]
           ,[Obis]
           ,[Zaehlerstand]
           ,[Ablesedatum]
           ,[Strasse]
           ,[Hausnummer]
           ,[Hausnummer_Zusatz]
           ,[Plz]
           ,[Ort])
		select distinct
			kunden_nummer as Kundennummer,
			geschaeftspartner_name as Geschaeftspartner,
			geschaeftspartner_name2 as Geschaeftspartner2,
			geschaeftspartner_zusatz as Geschaeftspartner_Zusatz,
			anrede as Anrede,
			k.id_person,
			person_vorname as Vorname,
			person_name as Nachname,
			k.telefonnummer,
			k.mobilnummer,
			k.faxnummer,
			k.email,
			--zp.meteringcode,
			ea.energieart as Energieart,
			--zpt.zaehlpunkttyp,
			zp.abnahmestelle_adresse as Abnahmestelle,
			zaehlernummer as Zaehlernummer,
			--einbaudatum as Einbaudatum,
			isnull(zws.obis,'-') as Obis,
			zws.zaehlerstand as Zaehlerstand,
			zws.ablesedatum as Ablesedatum,
			zp.abnahmestelle_straße as Strasse,
			zp.abnahmestelle_hausnummer as Hausnummer,
			zp.abnahmestelle_hausnummer_zusatz as Hausnummer_Zusatz,
			zp.abnahmestelle_plz as Plz,
			zp.abnahmestelle_ort as Ort
		from
			core.kunden k
		join
			core.link_kunde_zaehlpunkt lkz 
		on 
			k.id_mandant = lkz.id_mandant 
			and k.id_kunde = lkz.id_kunde 
			and getdate() between lkz.valid_from and lkz.valid_to 
			and lkz.id_status in (1,2,3,4) -- status erweitert
		join
			core.zaehlpunkte zp on lkz.id_zp = zp.id_zp and k.id_mandant = zp.id_mandant
		join
			core.energiearten ea on zp.id_energieart = ea.id_energieart
		join
			core.zaehlpunkt_typen zpt on zp.id_zp_typ = zpt.id_zp_typ
		join
			geraete lzpg on zp.id_zp = lzpg.id_zp and k.id_mandant = lzpg.id_mandant
		left join
			zaehlwerkstand zws on lzpg.ZPG_ID = zws.ZPG_ID
		where
			k.id_mandant = 1
			and k.id_kundenstatus in (1,2,9) and isnull(rollenstatus,'ACT') = 'ACT'
			and try_cast(left(id_kundenkategorie,2) as int) <=49 -- Keine Marktpartner (lief, MSB, etc)
			and GETDATE() between k.valid_from and k.valid_to
			and zws.zaehlerstand is not null


		-- housekeeping
		IF OBJECT_ID(N'tempdb..#tmp_ablesekarten') IS NOT NULL
			drop table #tmp_ablesekarten

	--	---------------------------------------------------
	END TRY
	--	---------------------------------------------------
	BEGIN CATCH

		-- alte inhalte wiederherstellen und housekeeping
		IF OBJECT_ID(N'tempdb..#tmp_ablesekarten') IS NOT NULL
		BEGIN
			
			insert into [mart_dsai].[Ablesekarten]
			   ([Kundennummer]
			   ,[Geschaeftspartner]
			   ,[Geschaeftspartner2]
			   ,[Geschaeftspartner_Zusatz]
			   ,[Anrede]
			   ,[id_person]
			   ,[Vorname]
			   ,[Nachname]
			   ,[telefonnummer]
			   ,[mobilnummer]
			   ,[faxnummer]
			   ,[email]
			   ,[Energieart]
			   ,[Abnahmestelle]
			   ,[Zaehlernummer]
			   ,[Obis]
			   ,[Zaehlerstand]
			   ,[Ablesedatum]
			   ,[Strasse]
			   ,[Hausnummer]
			   ,[Hausnummer_Zusatz]
			   ,[Plz]
			   ,[Ort])			
			select
			   [Kundennummer]
			   ,[Geschaeftspartner]
			   ,[Geschaeftspartner2]
			   ,[Geschaeftspartner_Zusatz]
			   ,[Anrede]
			   ,[id_person]
			   ,[Vorname]
			   ,[Nachname]
			   ,[telefonnummer]
			   ,[mobilnummer]
			   ,[faxnummer]
			   ,[email]
			   ,[Energieart]
			   ,[Abnahmestelle]
			   ,[Zaehlernummer]
			   ,[Obis]
			   ,[Zaehlerstand]
			   ,[Ablesedatum]
			   ,[Strasse]
			   ,[Hausnummer]
			   ,[Hausnummer_Zusatz]
			   ,[Plz]
			   ,[Ort]
			from 
				#tmp_ablesekarten

			drop table #tmp_ablesekarten

		END

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
