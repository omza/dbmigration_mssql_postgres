-- Object: core.energydhw_transform_main
-- Type  : SQL_STORED_PROCEDURE





/* =============================================
-- Author:		Oliver Meyer
-- Create date: 14.11.2024
-- Description:	
	
	Führt Kontextbezogen die notwendigen Aktualisierungen im DWH und in den Martlayern durch
	
-- Change Log
	14.11.2024	OME initial
	09.12.2024	OME	sub Prozeduren nicht ausführen, wenn eine gesperrte Source Tabelle dabei ist 
	07.02.2024	OMe Kontext für core.zaehlpunkte
	13.02.2024	OMe	Kontext für core.geraetetypen
	07.03.2024	OMe	Kontext für Gerätetypen erweitern um wilken_ensztp
	12.03.2025	OMe Kontext für switch_power_nedi mfg messpunkte
	13.03.2025	OMe Kontext für switch_power_nedi ipueps messpunkte
	24.03.2025	OMe	Kontext für Messwerte powerswitch saga mfg
	26.03.2025	OMe	Kontext für Gerätetypen nochmal aufgesplittet
	26.03.2025	OMe	Kontext für Messwerte powerswitch saga ipueps
	23.04.2025	OMe	Kontext für deZem Messpunkte und Messwerte
	29.04.2025	OMe	argos Lastgang Messwerte
	06.06.2025	OMe	Kontext für Wilken Kunden -> core.kunden
	30.06.2025	OMe	Kontext für Link Kunde zu Zählpunkt
	21.07.2025	OMe	Kontext Geolocation 
	23.07.2025	OMe	Kontext Fallgruppen
	16.09.2025	OMe	Kontext für Kundengruppen und kategorien
	10.10.2025	OMe	Kontext für [raw].[element_iot_devices]
	22.10.2025	OME			Wasserzähler aus element hinzu

	10.12.2025	OMe	Aufruf für mart_energieportfoliomanagement.load_fact_faernwaerme_kundenentwicklung bei core.kunden, core zaehlpunkte, core.link_zp_kunde eingefügt

	15.12.2025	OMe Kontext für Geraete und link_zaehlpunkt_geraet
	16.12.2025	OMe	Kontext für wilken_enzpzstand -> dsai.Ablesekarten aktualisieren

	16.01.2026	OMe	Nach Rücksprache mit Saliha brauchen wir die kundenentwicklung nur jährlich - das lässt sich mit Views machen
						- also wieder ausbauen

	09.02.2026	OMe	Global Verbose Einstellung

	26.02.2026	OMe	Netze und Produkte

	--02.03.2026	OMe Kontext für Privatkundenreport

	18.06.2026	OME	Kontext für Spannungsebenen

	23.06.2026	OMe Kontext für Gerätebeziehungen, ablesetouren
	26.06.2026	OME	Kontext für Lastprofile & Zaehlverfahren

	10.07.2026	OME	Kontext für Lokationsbündel

	13.07.2026	OME	Housekeeping einbauen, technische ressourcen

	08.09.2026	OMe	Messtellenbereiber am Zählpunkt

	23.09.2026	OMe	Kontext für Einspeiseanlagen

	19.10.2026	OMe	Kontext für abgerechnete Jahresverbräuche
	20.10.2026	OMe	Kontext für prognosegrundlagen schlüssel
								Zählpunkt bilanzierungsdaten


-- Test:
	exec core.[energydhw_transform_main]  -1


-- ============================================= 
--*/
CREATE PROCEDURE [core].[energydhw_transform_main]
	@transform_job_id bigint
AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;


	BEGIN TRY

		DECLARE 
			@CONTEXT AS TABLE ([transform_source] nvarchar(1000))
			
		
		DECLARE
			@LOADS AS TABLE ([transform_source] nvarchar(1000), transform_locked int)

		DECLARE
			@CONTEXT_CHANGED AS INT = 0,
			@TRANSFORM_COUNT AS INT = 0,
			@TRANSFORM_LOCKED AS INT = 0,
			@VERBOSE as TINYINT = 1 -- Globale Einstellung für Logging in der admin.transform_log_detail


		-- Prüfe ob die Job ID ausgeführt werden muss
		INSERT INTO @LOADS (transform_source, transform_locked)
		SELECT 
			transform_source, 
			case when transform_message = 'locked' then 1 else 0 end as transform_locked 
		FROM 
			admin.transform_log 
		WHERE 
			transform_job_id = @transform_job_id 
			AND transform_status = 0
		

		IF @@ROWCOUNT = 0

			-- Job id wurde bereits abgearbeitet
			SELECT
				@transform_job_id as transform_log_id,
				1 as transform_status,
				'Job wurde bereits durchgeführt oder kein Kontext gefunden' as transform_message	

		ELSE
		BEGIN


			-- Sub Prozeduren werden nur ausgeführt, wenn sich die Datengrundlage über die load programme geändert hat
			-- Die Logik welche dwh modelle betroffen sind und in welcher Reihenfolge diese abgefragt und verarbeitet werden
			-- ist hier im coding hinterlegt

			-- Stellt Euch diese SP als LOAD_DWH Variante vor, mit dem Unterschied das die Aufrufe der Sub -Load SPs nur erfolgt wenn
			-- sich die Daten geändert haben und dies wird hier hardcoded hinterlegt

			/*
				wilken_enmnd
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enmnd')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.mandant
				EXEC core.[load_mandant] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END

			/*
				wilken_crena
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_crena')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.energiearten
				EXEC core.[load_energiearten] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END

			/*
				wilken_lastprofil
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enlastprofil')--[raw].[wilken_enlastprofil]

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.lastprofile
				EXEC core.[load_lastprofile] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END


			/*
				[raw].[wilken_edprggrundlage]
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_edprggrundlage')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.lastprofile
				EXEC core.load_prognosegrundlage @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END

			/*
				wilken_zaehlverfahren
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enzaehlverfahren')--[raw].[wilken_enzaehlverfahren]

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.zaehlverfahren
				EXEC core.[load_zaehlverfahren] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END

			/*
				[wilken_enmessstellenbetreiber]
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enmessstellenbetreiber')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.messstellenbetreiber
				EXEC core.[load_messtellenbetreiber] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END

			/*
				wilken_ennet
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_ennet')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.energiearten
				EXEC core.[load_netze] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END



			/*
				wilken_enobis
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enobis')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.obis
				EXEC core.load_obis @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END

			-- core.kundengruppen aktualisieren
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enkng')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.obis
				EXEC core.load_kundengruppen @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END

			-- core.kundenkategorie aktualisieren
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enkategorie')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.obis
				EXEC core.load_kundenkategorie @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END

			-- core.produkte aktualisieren
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_crprodukt'),('wilken_crproduktvarianten')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN

				EXEC core.[load_produkte] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END

			-- core.vertraege aktualisieren
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_crgpvertrag'),('wilken_crgpvertraglink')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN

				EXEC core.[load_vertraege] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

				EXEC core.[load_link_kunde_zaehlpunkt] @transform_job_id, @VERBOSE
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END


			-- core.kunde aktualisieren
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_g4bm_gsprolle'),
				('wilken_g4bm_gspartner'),
				('wilken_g4bm_gspkmwadrvwnd'),
				('wilken_g4bm_gspadresse'),
				('wilken_enknd'),
				('wilken_g4bm_gspadrzeit'),
				('wilken_g4bm_gspersart'),
				('wilken_g4bm_gspperson'),
				('wilken_g4bm_anrede'),
				('wilken_g4bm_titel')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN

				EXEC core.load_kunden @transform_job_id, @VERBOSE
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
	

			END


			-- core.spannungsebenen aktualisieren
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enspannungsebene')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN

				exec [core].[load_spannungsebenen] @transform_job_id, @VERBOSE
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

			END




			/*
				wilken_enzpt und [wilken_enabn]  -> core.zaehlpunkte
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enabn'), ('wilken_enzpt'), ('wilken_enmes'), ('wilken_enzmk'), ('address_geolocation'), ('wilken_enzpn')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.zaehlpunkte
				EXEC core.load_zaehlpunkte @transform_job_id, @VERBOSE
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

				EXEC core.[load_link_kunde_zaehlpunkt] @transform_job_id, @VERBOSE
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

				EXEC core.load_fallgruppen @transform_job_id, @VERBOSE
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1



			END

			/*
				('wilken_enzptmlk'), ('wilken_enmlk') -> core.marktloaktionen
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enzptmlk'), ('wilken_enmlk')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.marktloaktionen
				EXEC [core].[load_marktlokationen] @transform_job_id, @VERBOSE
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END

			-- core.load_lieferanten aktualisieren
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enlieferant')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN

				EXEC core.load_lieferanten @transform_job_id, @VERBOSE
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

			END
	


			/*
				core.load_geraetetypen
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enzaehlertyp')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.geraetetypen
				EXEC core.load_geraetetypen @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END

			/*
				core.load_geraetetypen_standard
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_ensztp')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.geraetetypen
				EXEC [core].[load_standard_geraetetypen] @transform_job_id, @VERBOSE
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

			END


			/*
				 core.geraete und core.link_zaehlpunkt_geraet
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enzaehlerlos'), ('wilken_enzaehler'), ('wilken_enzenr'), ('wilken_enzpgd'), ('wilken_enzptgeraet')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.geraete
				EXEC [core].[load_geraete] @transform_job_id, @VERBOSE
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

				EXEC [core].[load_link_zaehlpunkt_geraet] @transform_job_id, @VERBOSE
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1


			END




			/*
				argos lastgang
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('argos_lastgang')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN

				EXEC core.load_argos_lastgang @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

				EXEC core.load_wertstatus @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

				exec core.[load_argos_messpunkte_und_werte] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

			END



			-- Schritt 1 Kontext  für Sub Prozedure rausfinden
			/*
			DELETE FROM @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enkndverbrauchabgr'),
				('wilken_enkndverbrauch'),
				('wilken_enzpt'),
				('wilken_enabn'),
				('wilken_enmes'),
				('wilken_enzptgeraet'),
				('wilken_enzaehler'),
				('wilken_engeraeteplatz'),
				('wilken_engeraeteart'),
				('wilken_kunde_kat_adresse'),
				('wilken_enzaehlertyp')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			SET @CONTEXT_CHANGED = (SELECT 
										ISNULL(COUNT(*),0)
									FROM 
										@LOADS L 
									JOIN 
										@CONTEXT C ON L.transform_source = C.transform_source)
			-- Sind tabellen im Kontext etwa gesperrt ?
			SET @TRANSFORM_LOCKED = (SELECT 
										ISNULL(COUNT(*),0)
									FROM 
										@LOADS L 
									JOIN 
										@CONTEXT C ON L.transform_source = C.transform_source
									WHERE
										L.transform_locked = 1)

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN

				-- Lade mart layer Fernwärme TK Kundenverbräuche
				--EXEC [dwh].[LOAD_MART_FW_tk_zp_verbrauch]
				--SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

				-- Lade mart layer Fernwärme Abgegrenzte Verbräuche je Jahr 
				--EXEC [dwh].[LOAD_MART_FW_fw_zp_verbrauch]
				--SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1



			END
			*/

			/*
				switch power und nedi devices
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('nedi_devices'), ('nedi_interfaces'),('nedi_inventory'), ('nedi_modules')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN

				exec core.load_geraetetypen_powerswitch @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
				
				EXEC [core].[load_messpunkte_powerswitch_sagamfg] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

				EXEC [core].load_messpunkte_powerswitch_sagaipuep @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

				-- hiermit werden auch die berechneten Leistungswerte für IPUEPS aus nedi ermittelt
				EXEC [core].[load_messwerte_powerswitch_sagaipuep] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

			END

			/*
				switch power mfg messungen
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('power_switch_power_eltek_saga')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = SUM(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				
				EXEC [core].[load_messwerte_powerswitch_sagamfg] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

			END



			/*
				deZem Messpunkte und Werte aus den Vorkonfigurierten CSV Exporten (Api) aus unserem Dezem Saas Mandanten für das Rechenzentrum RZ2.1 Heidbergstraße

			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('dezem_rz21_swn')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = SUM(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				
				exec core.[load_dezem_messpunkte_und_werte]  @transform_job_id, 'dezem_rz21_swn', 0
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

			END

			/*
				deZem Messpunkte und Werte aus den Vorkonfigurierten CSV Exporten (Api) aus unserem Dezem Saas Mandanten für das Rechenzentrum RZ2.1 Heidbergstraße

			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('dezem_rz21_wtg')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = SUM(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				
				exec core.[load_dezem_messpunkte_und_werte]  @transform_job_id, 'dezem_rz21_wtg', 0
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

			END


			-- ----------------------------------------------------------------------------------------------------------------------------------------------------
			/*
				lade Messpunkte aus element iot devices
			*/
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('element_iot_devices')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = SUM(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				
				exec core.load_messpunkte_elementiot_stromzaehler @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

				exec [core].[load_messpunkte_elementiot_waermezaehler] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
				
				exec [core].[load_messpunkte_elementiot_wasserzaehler] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1

			END
			-- ---------------------------------------------------------------------------------------------------------------------------------------

			-- mart_dsai.Ablesekarten aktualisieren
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enzpzstand')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.obis
				EXEC mart_dsai.load_ablesekarten @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END
			--------------------------------------------------------------------------------------


			-- core.link_geraetebeziehungen
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_engeraetebeziehung'), ('wilken_engeraetebeziehungdef'), ('[raw].[wilken_enzptgeraet]')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.link_geraetebeziehungen
				EXEC core.load_link_geraetebeziehungen @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END
			--------------------------------------------------------------------------------------

			-- core.ablesetouren
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enlauftour')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
				-- Lade core.link_ablesetouren
				EXEC core.load_ablesetouren @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END
			--------------------------------------------------------------------------------------

			-- core.lokationsbuendel und core.lokationsbuendelstruktur
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enlokbuendelzeit'),
				('wilken_enlokbuendelelement'),
				('wilken_enlokationsbuendelstruktur'),
				('wilken_enlokationsbuendel'),
				('wilken_enlokstrukturobjekt')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
 
				EXEC core.load_lokationsbuendel @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END
			--------------------------------------------------------------------------------------


			-- core.technische_ressourcen 
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_entremarktlokation'),
				('wilken_entechnischeressource'),
				('wilken_entredaten'),
				('wilken_wilken_ensvba'),
				('wilken_wilken_edwaen'),
				('wilken_entremesslokation')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
 
				EXEC core.load_technische_ressourcen @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END
			--------------------------------------------------------------------------------------

			-- core.einspeiseanlagen 
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enespnetzverknuepfungspunkt'),
				('wilken_enespanlnvp'),
				('wilken_enespzptanlage'),
				('wilken_enespanlstromerzeugungseinheit'),
				('wilken_enespanlage'),
				('wilken_enespenergietraeger')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
 
				EXEC core.load_einspeiseanlagen @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END
			--------------------------------------------------------------------------------------

			-- [core].[zaehlpunkt_jahresverbraeuche_abgerechnet] 
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enzptem'),
				('wilken_enzptma')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
 
				EXEC [core].[load_zaehlpunkt_jahresverbraeuche_abgerechnet] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END
			--------------------------------------------------------------------------------------


			-- [core].[zaehlpunkt_bilanzierungsdaten]
			--------------------------------------------------------------------------------------
			delete from @CONTEXT
			INSERT INTO @CONTEXT (transform_source)
			VALUES 
				('wilken_enzpbdaten')

			-- Wurden tabellen im Kontext neu geladen (getriggert)?
			-- Sind tabellen im Kontext etwa gesperrt ?
			SELECT 
				@CONTEXT_CHANGED = ISNULL(COUNT(*),0),
				@TRANSFORM_LOCKED = sum(case when L.transform_locked = 1 then 1 else 0 end)
			FROM 
				@LOADS L 
			JOIN 
				@CONTEXT C ON L.transform_source = C.transform_source

			IF @CONTEXT_CHANGED > 0 AND @TRANSFORM_LOCKED = 0
			BEGIN
 
				EXEC [core].[load_zaehlpunkt_bilanzierungsdaten] @transform_job_id
				SET @TRANSFORM_COUNT = @TRANSFORM_COUNT + 1
			END
			--------------------------------------------------------------------------------------



			-- ENDE
			SELECT
				@transform_job_id as transform_job_id,
				1 as transform_status,
				CAST(@TRANSFORM_COUNT AS VARCHAR) + ' Subprozeduren aufgerufen. Transformationsjob abgeschlossen' as transform_message		


			-- HOUSEKEEPING
			exec admin.[start_housekeeping] @transform_job_id

		END

	END TRY
	BEGIN CATCH

		SELECT
			@transform_job_id as transform_job_id,
			2 as transform_status,
			ERROR_MESSAGE() as transform_message

	END CATCH

END

GO
