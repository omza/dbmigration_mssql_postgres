-- Object: stage.load_aktive_vertraege
-- Type  : SQL_STORED_PROCEDURE




/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		[stage].[load_aktive_vertraege]

-- Change Log
	22.10.2026	OME initial
					Umstellung bei Monatskunden gehe erst auf Bilanzierungsmenge 

-- Test:
	exec [stage].[load_aktive_vertraege] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[stage].[load_aktive_vertraege]
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
		
		declare @stichtag date = cast(getdate() as date) -- immer heute
		


		-- Aktive Verträge über alle Energiearten immer aktuell halten 
		---------------------------------------------------------------------------------------

		-- Temporäre Tabelle anlegen
		IF OBJECT_ID('tempdb..#kunden') IS NOT NULL
			DROP TABLE #kunden


		;with kundenstatus  as (
			select 
				cast([wert] as int) as id_kundenstatus
				,[definition] as kundenstatus
			from 
				[core].[schluesseldefinition]
			where
				[feldname] = 'id_kundenstatus'
			)
			select
				k.id_kunde,
				k.id_kundengruppe,
				k.id_kundenkategorie,
				k.id_turnusrechnung,
				case 
					when k.id_turnusrechnung = 3 then 'monatlich'
					else ''
				end as turnusrechnung,
				k.kunden_nummer,
				k.id_kundenstatus,
				ks.kundenstatus,
				k.einzugsdatum,
				k.auszugsdatum
			into
				#kunden
			from
				core.kunden k 
			join
				kundenstatus ks on k.id_kundenstatus = ks.id_kundenstatus			
			where
				k.active = 1
				and k.[id_kundenstatus] not in(7, 8) -- gesperrte Kunden werden auch angezeigt (also auch status 9)

		-- Indiziere 
		CREATE NONCLUSTERED INDEX ix_kunde_idkunde ON #kunden (id_kunde)

		-- Temporäre Tabelle anlegen
		IF OBJECT_ID('tempdb..#bilanzierungsmengen') IS NOT NULL
			DROP TABLE #bilanzierungsmengen

		select
			id_zp,
			jahresentnahme_kwh
		into
			#bilanzierungsmengen
		from
				[core].[zaehlpunkt_bilanzierungsdaten] bil 
		where
			getdate() between bil.[gueltig_ab] and bil.gueltig_bis
			and id_mandant = 1
		-- Indiziere 
		CREATE NONCLUSTERED INDEX ix_bilanzierungsmengen ON #bilanzierungsmengen (id_zp)

		-- Temporäre Tabelle anlegen
		IF OBJECT_ID('tempdb..#abgerechneteverbraeuche') IS NOT NULL
			DROP TABLE #abgerechneteverbraeuche

		select
			id_link_messeinheit,
			id_energieart,
			Jahresverbrauch_kwh_gesamt,
			Jahresverbrauch_kwh_nt
		into
			#abgerechneteverbraeuche
		from
			core.zaehlpunkt_jahresverbraeuche_abgerechnet abgr 
		where
			abgr.messeinheit_letzte_zeitscheibe = 1
			and dateadd(DAY,365,abgr.[gueltig_bis]) >= @stichtag

		
		-- Indiziere 
		CREATE NONCLUSTERED INDEX ix_abgerechneteverbraeuche_mesid ON #abgerechneteverbraeuche (id_link_messeinheit)


		-- Temporäre Tabelle anlegen
		IF OBJECT_ID('tempdb..#messeinheit') IS NOT NULL
			DROP TABLE #messeinheit

		;with marktlokation as (

			select
				id_zp,
				malo
			from
				core.marktlokationen malo with (nolock) 
			where 
				id_energierichtung = 1 
				and malo.active = 1 
		)
		select
			lkz.id_link_messeinheit,
			lkz.id_mandant,
			zp.id_energieart,
			ea.energieart,	
			lkz.id_zp,
			lkz.id_kunde,
			lkz.id_vertrag,
			lkz.id_status as id_status_mes,
			lkz.status as status_mes,
			lkz.id_vertragsart as id_vertragsart_mes,
			lkz.vertragsart as vertragsart_mes,
			zp.meteringcode,
			lkz.id_lieferant,

			zp.id_spannungsebene,
			case when lkz.id_vertragsart = 6 then 2 else 1 end as id_energierichtung,
			zp.abnahmestelle_adresse,

			n.netz_nummer,
			n.netz,
			n.id_netz,

			lp.lastprofil,
			lp.edicode as lastprofil_edicode,

			zv.zaehlverfahren,
			zv.edicode as zaehlverfahren_edicode,

			malo.malo
		into
			#messeinheit
		from
			core.link_kunde_zaehlpunkt lkz with (nolock)

		join
			core.zaehlpunkte zp with (nolock) on lkz.id_zp = zp.id_zp

		join
			core.netze n with (nolock) on zp.id_netz = n.id_netz
		join
			core.energiearten ea with (nolock) on zp.id_energieart = ea.id_energieart 

		left join
			core.lastprofile lp with (nolock) on zp.id_lastprofil = lp.id_lastprofil

		left join
			core.zaehlverfahren zv with (nolock) on zp.id_mandant = zv.id_mandant and zp.id_zaehlverfahren = zv.id_zaehlverfahren

		left join
			marktlokation malo on lkz.id_zp = malo.id_zp

		where
			lkz.id_vertragsart in (1,2,6) -- Netznutzungsverträge und Einspeisevertraege hinzu

			and lkz.id_status not in(0, 7, 8, 9)

		
		-- Indiziere 
		CREATE NONCLUSTERED INDEX ix_messeinheit_vertrag ON #messeinheit (id_vertrag)
		CREATE NONCLUSTERED INDEX ix_messeinheit_kunde ON #messeinheit (id_kunde)
		CREATE NONCLUSTERED INDEX ix_messeinheit_link ON #messeinheit (id_link_messeinheit)

		-- Temporäre Tabelle anlegen
		IF OBJECT_ID('tempdb..#vertraege') IS NOT NULL
			DROP TABLE #vertraege
	
		;with vertragsstatus as (

			select 
				cast([wert] as int) as id_vertragsstatus
				,[definition] as vertragsstatus
			from 
				[core].[schluesseldefinition]
			where
				[feldname] = 'id_vertragsstatus'

		),	
		vertragsart as (
			select 
				cast([wert] as int) as id_vertragsart
				,[definition] as vertragsart
			from 
				[core].[schluesseldefinition]
			where
				[feldname] = 'id_vertragsart'
		)
		select
			v.id_vertrag,
			v.id_produkt,
			v.id_produktvariante,

			v.vertragsnummer,
			v.id_vertragsstatus,
			vs.vertragsstatus,
			v.id_vertragsart,
			va.vertragsart,
			v.belieferung_ab,
			v.belieferung_bis,
			v.created_at as vertrag_angelegt_am,
			v.vertragsbindung_bis,
			v.kuendigungsfrist_ablauf,
			p.produkt_nummer,
			p.produkt,
			p.variante_nummer,
			p.variante
		into
			#vertraege
		from
			core.vertraege v 

		join
			vertragsstatus vs on v.id_vertragsstatus = vs.id_vertragsstatus

		join
			vertragsart va on v.id_vertragsart = va.id_vertragsart		
		
		join
			core.produkte p  on v.id_produkt = p.id_produkt and v.id_produktvariante = p.id_produktvariante

		where
			v.id_vertragsstatus not in(7, 8, 9)
			and cast(getdate() as date) between v.belieferung_ab and v.belieferung_bis

		CREATE NONCLUSTERED INDEX ix_vertraege ON #messeinheit (id_vertrag)


		BEGIN TRANSACTION

			truncate table [stage].[wilken_aktive_vertraege]

			INSERT INTO [stage].[wilken_aktive_vertraege]
			   ([id_link_messeinheit]
			   ,[id_mandant]
			   ,[id_energieart]
			   ,[energieart]
			   ,[id_zp]
			   ,[id_kunde]
			   ,[id_vertrag]
			   ,[id_produkt]
			   ,[id_produktvariante]
			   ,[id_status_mes]
			   ,[status_mes]
			   ,[id_vertragsart_mes]
			   ,[vertragsart_mes]
			   ,[meteringcode]
			   ,[malo]
			   ,[abnahmestelle_adresse]
			   ,[netz_nummer]
			   ,[netz]
			   ,[kunden_nummer]
			   ,[id_kundenstatus]
			   ,[kundenstatus]
			   ,[einzugsdatum]
			   ,[auszugsdatum]
			   ,[vertragsnummer]
			   ,[id_vertragsstatus]
			   ,[vertragsstatus]
			   ,[id_vertragsart]
			   ,[vertragsart]
			   ,[belieferung_ab]
			   ,[belieferung_bis]
			   ,[vertrag_angelegt_am]
			   ,[vertragsbindung_bis]
			   ,[kuendigungsfrist_ablauf]
			   ,[produkt_nummer]
			   ,[produkt]
			   ,[variante_nummer]
			   ,[variante]
			   ,[jahresverbrauch]
			   ,[jahresverbrauch_ht]
			   ,[jahresverbrauch_nt]
			   ,[lastprofil]
			   ,[lastprofil_edicode]
			   ,[zaehlverfahren]
			   ,[zaehlverfahren_edicode]
			   ,[id_kundengruppe]
			   ,[id_kundenkategorie]
			   ,[id_turnusrechnung]
			   ,[turnusrechnung]
			   ,[id_lieferant]
			   ,[id_spannungsebene]
			   ,[id_energierichtung]
			   ,[id_netz]
			   ,jahresverbrauch_kwh_abgerechnet
			   ,jahresverbrauch_kwh_bilanziert
			   )
			select distinct
				lkz.id_link_messeinheit,
				lkz.id_mandant,
				lkz.id_energieart,
				lkz.energieart,	
				lkz.id_zp,
				lkz.id_kunde,
				lkz.id_vertrag,
				v.id_produkt,
				v.id_produktvariante,

				lkz.id_status_mes,
				lkz.status_mes,
				lkz.id_vertragsart_mes,
				lkz.vertragsart_mes,
				lkz.meteringcode,
				lkz.malo,
				lkz.abnahmestelle_adresse,
				lkz.netz_nummer,
				lkz.netz,
				k.kunden_nummer,
				k.id_kundenstatus,
				k.kundenstatus,
				k.einzugsdatum,
				k.auszugsdatum,
				v.vertragsnummer,
				v.id_vertragsstatus,
				v.vertragsstatus,
				v.id_vertragsart,
				v.vertragsart,
				v.belieferung_ab,
				v.belieferung_bis,
				v.vertrag_angelegt_am,
				v.vertragsbindung_bis,
				v.kuendigungsfrist_ablauf,

				v.produkt_nummer,
				v.produkt,
				v.variante_nummer,
				v.variante,

				case
					when k.id_turnusrechnung = 3 then isnull(bil.[jahresentnahme_kwh], isnull(abgr.[Jahresverbrauch_kwh_gesamt],0)) -- bei monatskunden erst die bilanzierungssumme, danach die abrechnungssumme
					else isnull(abgr.[Jahresverbrauch_kwh_gesamt], isnull(bil.[jahresentnahme_kwh],0)) 
				end	as jahresverbrauch,
				
				case
					when k.id_turnusrechnung = 3 then
						isnull(bil.[jahresentnahme_kwh], isnull(abgr.[Jahresverbrauch_kwh_gesamt],0))
					else
						case
							when abgr.[Jahresverbrauch_kwh_nt] is not null  then abgr.[Jahresverbrauch_kwh_gesamt] - abgr.[Jahresverbrauch_kwh_nt]
							else isnull(bil.[jahresentnahme_kwh],0)
						end
				end
				as jahresverbrauch_ht,
		
				case
					when k.id_turnusrechnung = 3 then 0
					else isnull(abgr.[Jahresverbrauch_kwh_nt],0) 
				end
				as jahresverbrauch_nt,

				lkz.lastprofil,
				lkz.lastprofil_edicode,

				lkz.zaehlverfahren,
				lkz.zaehlverfahren_edicode,

				k.id_kundengruppe,
				k.id_kundenkategorie,
				k.id_turnusrechnung,
				k.turnusrechnung,
				lkz.id_lieferant,
				lkz.id_spannungsebene,
				lkz.id_energierichtung,
				lkz.id_netz,

				abgr.[Jahresverbrauch_kwh_gesamt] as jahresverbrauch_kwh_abgerechnet,
				bil.[jahresentnahme_kwh] as jahresverbrauch_kwh_bilanziert

			from
				#messeinheit lkz 
			join
				#vertraege v on lkz.id_vertrag = v.id_vertrag

			join
				#kunden k  on lkz.id_kunde = k.id_kunde 

			left join
				#abgerechneteverbraeuche abgr
			on
				lkz.id_link_messeinheit = abgr.id_link_messeinheit
				--and lkz.id_energieart = abgr.id_energieart
	
			left join
				#bilanzierungsmengen bil
			on
				lkz.id_zp = bil.id_zp


		COMMIT TRANSACTION

		--Housekeeping
		---------------------------------------------------
		IF OBJECT_ID('tempdb..#kunden') IS NOT NULL
			DROP TABLE #kunden

		IF OBJECT_ID('tempdb..#bilanzierungsmengen') IS NOT NULL
			DROP TABLE #bilanzierungsmengen

		IF OBJECT_ID('tempdb..#abgerechneteverbraeuche') IS NOT NULL
			DROP TABLE #abgerechneteverbraeuche

		IF OBJECT_ID('tempdb..#messeinheit') IS NOT NULL
			DROP TABLE #messeinheit

		IF OBJECT_ID('tempdb..#vertraege') IS NOT NULL
			DROP TABLE #vertraege

	--	---------------------------------------------------
	END TRY
	--	---------------------------------------------------
	BEGIN CATCH

		IF @@TRANCOUNT > 0
			ROLLBACK TRAN

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
