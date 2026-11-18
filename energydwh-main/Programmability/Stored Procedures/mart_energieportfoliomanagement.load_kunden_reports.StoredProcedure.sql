-- Object: mart_energieportfoliomanagement.load_kunden_reports
-- Type  : SQL_STORED_PROCEDURE




/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		[mart_energieportfoliomanagement].[privatkunden_report_liefervertraege]
		[mart_energieportfoliomanagement].[kunden_report_netzvertraege]

-- Change Log

	02.03.2026	OME initial
	24.03.2026	OME	Hinzufügen der Zusammenfassungskategorie
	28.05.2026  OME Redesign der SP historisiert werden alle aktiven Verträge zum Stichtag, damit auch die Historie der aktiven Verträge im Report abgebildet wird. Die Zusammenfassungskategorie wird jetzt direkt in der Definitionstabelle gepflegt, damit sie flexibler ist und nicht mehr in der SP abgeleitet werden muss.
	02.06.2026  OME Verdichtung rausnehmen
	25.06.2026	OMe Umbenennen der SP und auch Netzverträge historisieren
	22.10.2026	OMe	Umstellung auf materializierte stage tabelle
					id_turnus rechnung hinzufügen


-- Test:

	exec [mart_energieportfoliomanagement].[load_kunden_reports] -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[mart_energieportfoliomanagement].[load_kunden_reports]
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
		
		declare @stichtag date 
		
		if day(getdate()) = 1 
			SET @stichtag = cast(getdate() as date)
		else
			SET @stichtag = dateadd(DAY,1,EOMONTH (getdate()))


		-- aktualisiere stage.tabelle
		EXECUTE [stage].[load_aktive_vertraege] 
		   @transform_job_id
		  ,@verbose


		-- Temporäre Tabelle anlegen für aktive Verträge Strom und  Gas
		IF OBJECT_ID('tempdb..#aktive_vertraege') IS NOT NULL
			DROP TABLE #aktive_vertraege

		select 
			*
		into
			#aktive_vertraege
		from 
			stage.[wilken_aktive_vertraege]
		where
			id_energieart in (1,2) -- nur Strom und Gas Verträge
		
		-- Indiziere Vertragsart und Netz
		CREATE NONCLUSTERED INDEX ix_aktive_vertraege_vertragsart ON #aktive_vertraege (id_vertragsart_mes)
		CREATE NONCLUSTERED INDEX ix_aktive_vertraege_netz ON #aktive_vertraege ([id_netz])

		-- Kundenreports Lieferant Strom und Gas
		---------------------------------------------------------------------------------------
		BEGIN TRANSACTION

			-- aktive Verträge historisieren
			

			-- erst aktuellen Monat löschen
			delete from [mart_energieportfoliomanagement].[privatkunden_report_liefervertraege] where stichtag = @stichtag

			--aktive Verträge zum Stichtag in Historie Tabelle laden
			insert into [mart_energieportfoliomanagement].[privatkunden_report_liefervertraege] (
				[stichtag]
			   ,[geaendert_am]
			   ,[id_link_messeinheit]
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
			   ,[id_turnusrechnung]
		   )
		   select distinct
			   @stichtag as stichtag
			   ,getdate() as geaendert_am
			   ,[id_link_messeinheit]
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
			   ,[id_turnusrechnung]
			from
				#aktive_vertraege
			where
				id_vertragsart_mes = 1 -- Nur Lieferantenverträge

		COMMIT TRANSACTION


		-- Netzkundenreports für eigenen Netzbereiber Strom und Gas
		-- aktive Verträge historisieren
		---------------------------------------------------------------------------------------
		BEGIN TRANSACTION
	
			-- erst aktuellen Monat löschen
			delete from [mart_energieportfoliomanagement].[kunden_report_netzvertraege] where stichtag = @stichtag

			--aktive Verträge zum Stichtag in Historie Tabelle laden
			;with eigene_netze as (

				select distinct 
					[id_netz]
				from 
					[core].[netze]
				where 
					id_mandant = 1
					and id_energieart in (1,2)
					and eigenes_netz = 1 

			)
			insert into [mart_energieportfoliomanagement].[kunden_report_netzvertraege] (
				[stichtag]
			   ,[geaendert_am]
			   ,[id_link_messeinheit]
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
				-- neu ab 25.06.26
				,lastprofil,
				lastprofil_edicode,
				zaehlverfahren,
				zaehlverfahren_edicode,
				id_kundengruppe,
				id_kundenkategorie,
				id_lieferant,
				id_spannungsebene,
				id_energierichtung,
				id_netz,
				[id_turnusrechnung]

		   )
		   select distinct
			   @stichtag as stichtag
			   ,getdate() as geaendert_am
			   ,[id_link_messeinheit]
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
				-- neu ab 25.06.26
				,lastprofil,
				lastprofil_edicode,
				zaehlverfahren,
				zaehlverfahren_edicode,
				id_kundengruppe,
				id_kundenkategorie,
				id_lieferant,
				id_spannungsebene,
				id_energierichtung,
				v.id_netz,
				[id_turnusrechnung]
			from
				#aktive_vertraege v
			join
				eigene_netze n on v.id_netz = n.id_netz

		COMMIT TRANSACTION



		--Housekeeping
		---------------------------------------------------
		IF OBJECT_ID('tempdb..#aktive_vertraege') IS NOT NULL
			DROP TABLE #aktive_vertraege

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
