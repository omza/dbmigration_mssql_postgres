-- Object: mart_dsai.load_kunden_milieus
-- Type  : SQL_STORED_PROCEDURE




/* =============================================
-- Author:		Oliver Meyer
-- Create date: 31.01.2026
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: mart_dsai.kunden_milieus 

/*
	Kundenfeatures Energie/SWNOR für dsai

	- Energieart
	- Verbrauch (Jahr)
	- unbundling_art
	- Geschlecht
	- GeburtsJAHR
	- Anrede
	- Titel
	- eMail vorhanden (1/0)
	- telefonnummer vorhanden (1/0)
	- mobilnummer vorhanden (1/0)
	- ! Surrogatkey über geschäftspartnername JE Adresse zur Identifikation der Person
	- id_kundengruppe
	- kundengruppe (bezeichnung)
	- id_kundenkategorie
	- kundenkategorie (bezeichnung)
	- Einspeiser (1/0)

	dazu alle infos aus den Sinusmillieus zur Adresse

*/

-- Change Log
	31.01.2026	OME initial
	01.04.2026	OMe	typumwandlung
	02.07.2026	OMe	Altersgruppen statt geburtsjahr

-- Test:
	exec mart_dsai.load_kunden_milieus -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[mart_dsai].[load_kunden_milieus]

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
		
		-- Dataset anlegen wenn noch nicht vorhanden
		IF OBJECT_ID (N'mart_dsai.kunden_milieus', N'U') IS NULL
			CREATE TABLE [mart_dsai].[kunden_milieus](
				[key_kunde] [varchar](32) NOT NULL,
				[energieart] [varchar](255) NOT NULL,
				[jahresverbrauch] [int] NULL,
				[unbundling_art] [varchar](18) NOT NULL,
				[geschlecht] [varchar](3) NULL,
				[altersgruppe] [int] not NULL,
				[anrede] [varchar](40) NULL,
				[titel] [varchar](40) NULL,
				[email_vorhanden] [int] NOT NULL,
				[telefon_vorhanden] [int] NOT NULL,
				[mobilnummer_vorhanden] [int] NOT NULL,
				[id_kundengruppe] [int] NOT NULL,
				[kundengruppe] [varchar](50) NOT NULL,
				[id_kundenkategorie] [char](3) NOT NULL,
				[kundenkategorie] [varchar](50) NOT NULL,
				[einspeiser] [int] NOT NULL,
				--[MB_HA_AD_N_Strasse] [varchar](255) NULL,
				--[MB_HA_AD_N_HNRkomplett] [varchar](50) NULL,
				[MB_HA_AD_N_PLZ] [int] NULL,
				--[MB_HA_AD_N_Ort] [varchar](255) NULL,
				--[MB_HA_AD_N_Ortsteil] [varchar](255) NULL,
				[MB_HA_BA_A_Haushalt] [int] NULL,
				[MB_HA_SI_P_KOG] [decimal](7, 2) NULL,
				[MB_HA_SI_P_PMA] [decimal](7, 2) NULL,
				[MB_HA_SI_P_PER] [decimal](7, 2) NULL,
				[MB_HA_SI_P_EPE] [decimal](7, 2) NULL,
				[MB_HA_SI_P_ADA] [decimal](7, 2) NULL,
				[MB_HA_SI_P_NOB] [decimal](7, 2) NULL,
				[MB_HA_SI_P_TRA] [decimal](7, 2) NULL,
				[MB_HA_SI_P_PRE] [decimal](7, 2) NULL,
				[MB_HA_SI_P_HED] [decimal](7, 2) NULL,
				[MB_HA_SI_P_NOK] [decimal](7, 2) NULL,
				[MB_HA_SI_K_DOM] [varchar](6) NULL
			) ON [PRIMARY]


		-- alter stand in tmp tabelle auslagern
		IF OBJECT_ID(N'tempdb..#tmp_kunden_milieus') IS NOT NULL
			drop table #tmp_kunden_milieus

		select * into #tmp_kunden_milieus from mart_dsai.kunden_milieus

		-- tabelle löschen
		truncate table mart_dsai.kunden_milieus;

		-- tabelle neu befüllen
		IF OBJECT_ID(N'tempdb..#tmp_milieus') IS NOT NULL
			drop table #tmp_milieus

		select 
			MB_HA_ID
			,cast(stage.adressabgleich(
				MB_HA_AD_N_Strasse,
				MB_HA_AD_N_HNRkomplett,'',
				MB_HA_AD_N_PLZ,
				MB_HA_AD_N_Ort
			)  as nvarchar(255)) as adresse
		into #tmp_milieus 
		from 
			raw.mbm_haus_sinusmilieus

		create nonclustered index idx_tmp_milieus on #tmp_milieus (adresse)

		IF OBJECT_ID(N'tempdb..#tmp_abnahmestellen') IS NOT NULL
			drop table #tmp_abnahmestellen


		select distinct
			id_abn
			,abnahmestelle_straße
			,abnahmestelle_hausnummer
			,abnahmestelle_hausnummer_zusatz
			,abnahmestelle_plz
			,abnahmestelle_ort
			,CAST('' as nvarchar(255)) as adresse
		into #tmp_abnahmestellen 
		from 
			core.zaehlpunkte
		where
			id_abn > 0

		update #tmp_abnahmestellen
		set
			adresse = stage.adressabgleich(
				abnahmestelle_straße
				,abnahmestelle_hausnummer
				,abnahmestelle_hausnummer_zusatz
				,abnahmestelle_plz
				,abnahmestelle_ort		
			)


		create nonclustered index idx_tmp_abnahmestellen on #tmp_abnahmestellen (adresse)


		;with bridge as (
			select
				id_abn,
				a.adresse,
				MB_HA_ID
			from 
				#tmp_abnahmestellen a
			join
				#tmp_milieus m on a.adresse = m.adresse
		)

		insert into [mart_dsai].[kunden_milieus]
			([key_kunde]
			,[energieart]
			,[jahresverbrauch]
			,[unbundling_art]
			,[geschlecht]
			,[altersgruppe]
			,[anrede]
			,[titel]
			,[email_vorhanden]
			,[telefon_vorhanden]
			,[mobilnummer_vorhanden]
			,[id_kundengruppe]
			,[kundengruppe]
			,[id_kundenkategorie]
			,[kundenkategorie]
			,[einspeiser]
			--,[mb_ha_ad_n_strasse]
			--,[mb_ha_ad_n_hnrkomplett]
			,[mb_ha_ad_n_plz]
			--,[mb_ha_ad_n_ort]
			--,[mb_ha_ad_n_ortsteil]
			,[mb_ha_ba_a_haushalt]
			,[mb_ha_si_p_kog]
			,[mb_ha_si_p_pma]
			,[mb_ha_si_p_per]
			,[mb_ha_si_p_epe]
			,[mb_ha_si_p_ada]
			,[mb_ha_si_p_nob]
			,[mb_ha_si_p_tra]
			,[mb_ha_si_p_pre]
			,[mb_ha_si_p_hed]
			,[mb_ha_si_p_nok]
			,[mb_ha_si_k_dom])

		select 

			convert(varchar(32), hashbytes('SHA2_512', ltrim(rtrim(isnull(k.geschaeftspartner_name,'')))+ltrim(rtrim(isnull(zp.abnahmestelle_adresse,'')))), 2) as key_kunde
			--,zp.id_zp
			,ea.energieart
			,try_cast(lkz.jahresverbrauch as int) jahresverbrauch
			,k.unbundling_art

			,k.geschlecht
			,isnull(case 
				when ISNUMERIC(year(k.geburtsdatum)) = 0 then -1
				when k.geburtsdatum > getdate() then -1
				when ABS(year(getdate()) - year(k.geburtsdatum)) > 100 then 10
				else ABS((year(getdate()) - year(k.geburtsdatum))/10)
			
			end,-1) as [altersgruppe]

			,k.anrede
			,k.titel
			,case when k.email is not null then 1 else 0 end email_vorhanden
			,case when k.telefonnummer is not null then 1 else 0 end telefon_vorhanden
			,case when k.mobilnummer is not null then 1 else 0 end mobilnummer_vorhanden

			,k.id_kundengruppe
			,kg.kundengruppe

			,k.id_kundenkategorie
			,kk.kundenkategorie

			,case when k.id_kundengruppe in (22,23) then 1 else 0 end einspeiser

		--
			--,left(ltrim(rtrim([MB_HA_AD_N_Strasse])),255) as [MB_HA_AD_N_Strasse]
			--,left(ltrim(rtrim([MB_HA_AD_N_HNRkomplett])),50) as [MB_HA_AD_N_HNRkomplett]
			,try_cast(ltrim(rtrim([MB_HA_AD_N_PLZ])) as int) as [MB_HA_AD_N_PLZ]
			--,left(ltrim(rtrim([MB_HA_AD_N_Ort])),255) as [MB_HA_AD_N_Ort]
			--,left(ltrim(rtrim([MB_HA_AD_N_Ortsteil])),50) as [MB_HA_AD_N_Ortsteil]
			,try_cast(ltrim(rtrim([MB_HA_BA_A_Haushalt])) as int) as [MB_HA_BA_A_Haushalt]
			,try_cast(ltrim(rtrim(replace([MB_HA_SI_P_KOG],',','.'))) as decimal(7,2)) as [MB_HA_SI_P_KOG]
			,try_cast(ltrim(rtrim(replace([MB_HA_SI_P_PMA],',','.'))) as decimal(7,2)) as [MB_HA_SI_P_PMA]
			,try_cast(ltrim(rtrim(replace([MB_HA_SI_P_PER],',','.'))) as decimal(7,2)) as [MB_HA_SI_P_PER]
			,try_cast(ltrim(rtrim(replace([MB_HA_SI_P_EPE],',','.'))) as decimal(7,2)) as [MB_HA_SI_P_EPE]
			,try_cast(ltrim(rtrim(replace([MB_HA_SI_P_ADA],',','.'))) as decimal(7,2)) as [MB_HA_SI_P_ADA]
			,try_cast(ltrim(rtrim(replace([MB_HA_SI_P_PMA],',','.'))) as decimal(7,2)) as [MB_HA_SI_P_NOB]
			,try_cast(ltrim(rtrim(replace([MB_HA_SI_P_NOB],',','.'))) as decimal(7,2)) as [MB_HA_SI_P_TRA]
			,try_cast(ltrim(rtrim(replace([MB_HA_SI_P_PRE],',','.'))) as decimal(7,2)) as [MB_HA_SI_P_PRE]
			,try_cast(ltrim(rtrim(replace([MB_HA_SI_P_HED],',','.'))) as decimal(7,2)) as [MB_HA_SI_P_HED]
			,try_cast(ltrim(rtrim(replace([MB_HA_SI_P_NOK],',','.'))) as decimal(7,2)) as [MB_HA_SI_P_NOK]
			,left(ltrim(rtrim([MB_HA_SI_K_DOM])),6) as [MB_HA_SI_K_DOM]

		--into
			--mart_dsai.kunden_milieus

		from
			core.link_kunde_zaehlpunkt lkz

		join
			core.kunden k 
		on 
			lkz.id_mandant = k.id_mandant
			and lkz.id_kunde = k.id_kunde

		join
			core.zaehlpunkte zp 
		on 
			lkz.id_mandant = zp.id_mandant
			and lkz.id_zp = zp.id_zp

		join
			core.energiearten ea 
		on 
			zp.id_energieart = ea.id_energieart

		join
			core.kundengruppen kg 
		on 
			lkz.id_mandant = kg.id_mandant
			and k.id_kundengruppe = kg.id_kundengruppe

		join
			core.kundenkategorie kk
		on 
			lkz.id_mandant = kk.id_mandant
			and k.id_kundenkategorie = kk.id_kundenkategorie


		join
			bridge b
		on
			zp.id_abn = b.id_abn

		join
			raw.mbm_haus_sinusmilieus m
		on
			b.MB_HA_ID = m.MB_HA_ID

		where
			getdate() between lkz.valid_from and lkz.valid_to
			and lkz.id_status not in (9)
			and lkz.id_mandant = 1
			and getdate() between k.valid_from and k.valid_to
			and unbundling_art not in ('Messstellenbetrieb')


		-- housekeeping
		IF OBJECT_ID(N'tempdb..#tmp_kunden_milieus') IS NOT NULL
			drop table #tmp_kunden_milieus

		IF OBJECT_ID(N'tempdb..#tmp_milieus') IS NOT NULL
			drop table #tmp_milieus
		
		IF OBJECT_ID(N'tempdb..#tmp_abnahmestellen') IS NOT NULL
			drop table #tmp_abnahmestellen

	--	---------------------------------------------------
	END TRY
	--	---------------------------------------------------
	BEGIN CATCH

		-- alte inhalte wiederherstellen und housekeeping
		IF OBJECT_ID(N'tempdb..#tmp_kunden_milieus') IS NOT NULL
		BEGIN

			insert into [mart_dsai].[kunden_milieus]
				([key_kunde]
				,[energieart]
				,[jahresverbrauch]
				,[unbundling_art]
				,[geschlecht]
				,[altersgruppe]
				,[anrede]
				,[titel]
				,[email_vorhanden]
				,[telefon_vorhanden]
				,[mobilnummer_vorhanden]
				,[id_kundengruppe]
				,[kundengruppe]
				,[id_kundenkategorie]
				,[kundenkategorie]
				,[einspeiser]
			--	,[mb_ha_ad_n_strasse]
				--,[mb_ha_ad_n_hnrkomplett]
				,[mb_ha_ad_n_plz]
			--	,[mb_ha_ad_n_ort]
			--	,[mb_ha_ad_n_ortsteil]
				,[mb_ha_ba_a_haushalt]
				,[mb_ha_si_p_kog]
				,[mb_ha_si_p_pma]
				,[mb_ha_si_p_per]
				,[mb_ha_si_p_epe]
				,[mb_ha_si_p_ada]
				,[mb_ha_si_p_nob]
				,[mb_ha_si_p_tra]
				,[mb_ha_si_p_pre]
				,[mb_ha_si_p_hed]
				,[mb_ha_si_p_nok]
				,[mb_ha_si_k_dom])

			select
				[key_kunde]
				,[energieart]
				,[jahresverbrauch]
				,[unbundling_art]
				,[geschlecht]
				,[altersgruppe]
				,[anrede]
				,[titel]
				,[email_vorhanden]
				,[telefon_vorhanden]
				,[mobilnummer_vorhanden]
				,[id_kundengruppe]
				,[kundengruppe]
				,[id_kundenkategorie]
				,[kundenkategorie]
				,[einspeiser]
				--,[MB_HA_AD_N_Strasse]
				--,[MB_HA_AD_N_HNRkomplett]
				,[MB_HA_AD_N_PLZ]
				--,[MB_HA_AD_N_Ort]
				--,[MB_HA_AD_N_Ortsteil]
				,[MB_HA_BA_A_Haushalt]
				,[MB_HA_SI_P_KOG]
				,[MB_HA_SI_P_PMA]
				,[MB_HA_SI_P_PER]
				,[MB_HA_SI_P_EPE]
				,[MB_HA_SI_P_ADA]
				,[MB_HA_SI_P_NOB]
				,[MB_HA_SI_P_TRA]
				,[MB_HA_SI_P_PRE]
				,[MB_HA_SI_P_HED]
				,[MB_HA_SI_P_NOK]
				,[MB_HA_SI_K_DOM]
			from 
				#tmp_kunden_milieus

			drop table #tmp_kunden_milieus

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
