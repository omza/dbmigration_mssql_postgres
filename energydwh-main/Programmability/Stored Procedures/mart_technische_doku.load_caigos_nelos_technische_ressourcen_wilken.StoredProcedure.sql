-- Object: mart_technische_doku.load_caigos_nelos_technische_ressourcen_wilken
-- Type  : SQL_STORED_PROCEDURE




/* =============================================
-- Author:		Oliver Meyer
-- Create date: 27.05.2026
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: [mart_technische_doku].[caigos_nelos_technische_ressourcen_wilken]


-- Change Log
	27.05.2026	OME initial
	03.06.2026	OME Anpassung Merge getrennt für technische Ressourcen und Nelos ohne technische Ressourcen
	11.06.2026	OMe Caigos Adressabgleich


-- Test:
	exec [mart_technische_doku].[load_caigos_nelos_technische_ressourcen_wilken] -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE [mart_technische_doku].[load_caigos_nelos_technische_ressourcen_wilken]

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
		
		-- In Ziel mergen dabei nicht ehr vorhandene Datensätze im Ziel markiere
		-- Technische Ressourcen von Wilken haben teilweise doppelte id_ressource, daher werden diese hier gefiltert, damit der Merge funktioniert
		update [mart_technische_doku].[caigos_technische_ressourcen_wilken]
		set 
			delta = '',
			pflegehinweis = ''


		;WITH doublette as (
				select 
					id_ressource
				from
					stage.wilken_technische_ressourcen
				group by
					id_ressource
				having count(*) > 1
		),
		TargetRows AS 
		(
			----- ZIEL -----
			select 
				[abnahmestelle_straße]
				,[abnahmestelle_hausnummer]
				,[abnahmestelle_hausnummer_zusatz]
				,[abnahmestelle_plz]
				,[abnahmestelle_ort]
				,[nelo]
				,[melo]
				,[malo_bezug]
				,[malo_einspeisung]
				,[id_ressource]
				,[ressource_nutzungsart]
				,[ressource_bemerkung]
				,[ressource_erzeugungsart]
				,[nennleistung_kw_abgabe]
				,[nennleistung_kw_aufnahme]
				,[speicherkapazitaet_kwh]
				,[stromverbrauchsart]
				,[waermenutzung]
				,[faellt_unter_enwg14a]
				,[inbetriebnahme_nach_2023]
				,[einordnung_enwg_vor2024]
				,[weitere_technische_einrichtungen]
				,[ressource_gueltig_ab]
				,[ressource_gueltig_bis]
				,[erstellt_am]
				,[geaendert_am]
				,[geloescht_am]
				,delta
				,CHECKSUM(
					[abnahmestelle_straße]
					,[abnahmestelle_hausnummer]
					,[abnahmestelle_hausnummer_zusatz]
					,[abnahmestelle_plz]
					,[abnahmestelle_ort]
					,[nelo]
					,[melo]
					,[malo_bezug]
					,[malo_einspeisung]
					,[id_ressource]
					,[ressource_nutzungsart]
					,[ressource_bemerkung]
					,[ressource_erzeugungsart]
					,[nennleistung_kw_abgabe]
					,[nennleistung_kw_aufnahme]
					,[speicherkapazitaet_kwh]
					,[stromverbrauchsart]
					,[waermenutzung]
					,[faellt_unter_enwg14a]
					,[inbetriebnahme_nach_2023]
					,[einordnung_enwg_vor2024]
					,[weitere_technische_einrichtungen]
					,[ressource_gueltig_ab]
					,[ressource_gueltig_bis]
				) as [checksum]
			  from 
				[mart_technische_doku].[caigos_technische_ressourcen_wilken] 

	
		)
		MERGE INTO TargetRows	AS	Target
		USING
		(
			----- QUELLE -----

			select 
				[abnahmestelle_straße]
				,[abnahmestelle_hausnummer]
				,[abnahmestelle_hausnummer_zusatz]
				,[abnahmestelle_plz]
				,[abnahmestelle_ort]
				,[nelo]
				,[melo]
				,[malo_bezug]
				,[malo_einspeisung]
				,[id_ressource]
				,[ressource_nutzungsart]
				,[ressource_bemerkung]
				,[ressource_erzeugungsart]
				,[nennleistung_kw_abgabe]
				,[nennleistung_kw_aufnahme]
				,[speicherkapazitaet_kwh]
				,[stromverbrauchsart]
				,[waermenutzung]
				,[faellt_unter_enwg14a]
				,[inbetriebnahme_nach_2023]
				,[einordnung_enwg_vor2024]
				,[weitere_technische_einrichtungen]
				,[ressource_gueltig_ab]
				,[ressource_gueltig_bis]
				,CHECKSUM(
					[abnahmestelle_straße]
					,[abnahmestelle_hausnummer]
					,[abnahmestelle_hausnummer_zusatz]
					,[abnahmestelle_plz]
					,[abnahmestelle_ort]
					,[nelo]
					,[melo]
					,[malo_bezug]
					,[malo_einspeisung]
					,[id_ressource]
					,[ressource_nutzungsart]
					,[ressource_bemerkung]
					,[ressource_erzeugungsart]
					,[nennleistung_kw_abgabe]
					,[nennleistung_kw_aufnahme]
					,[speicherkapazitaet_kwh]
					,[stromverbrauchsart]
					,[waermenutzung]
					,[faellt_unter_enwg14a]
					,[inbetriebnahme_nach_2023]
					,[einordnung_enwg_vor2024]
					,[weitere_technische_einrichtungen]
					,[ressource_gueltig_ab]
					,[ressource_gueltig_bis]
				) as [checksum]
			from 
				stage.wilken_technische_ressourcen
			where
				id_ressource not in (select id_ressource from doublette) -- doppelte Ressource nicht mergen sondern manuell prüfen

			----- QUELLE -----
		)
		AS Source	ON		
		
			Source.[id_ressource] = Target.[id_ressource]



		WHEN MATCHED AND Target.[checksum] <> Source.[checksum] and Target.geloescht_am is null THEN

			----- UPDATE, weil schon vorhanden -----
			UPDATE	SET 
				 Target.[abnahmestelle_straße]             = Source.[abnahmestelle_straße]            
				,Target.[abnahmestelle_hausnummer]         = Source.[abnahmestelle_hausnummer]        
				,Target.[abnahmestelle_hausnummer_zusatz]  = Source.[abnahmestelle_hausnummer_zusatz] 
				,Target.[abnahmestelle_plz]                = Source.[abnahmestelle_plz]               
				,Target.[abnahmestelle_ort]                = Source.[abnahmestelle_ort]               
				,Target.[nelo]                             = Source.[nelo]                            
				,Target.[melo]                             = Source.[melo]                            
				,Target.[malo_bezug]                       = Source.[malo_bezug]                      
				,Target.[malo_einspeisung]                 = Source.[malo_einspeisung]                
				,Target.[id_ressource]                     = Source.[id_ressource]                    
				,Target.[ressource_nutzungsart]            = Source.[ressource_nutzungsart]           
				,Target.[ressource_bemerkung]              = Source.[ressource_bemerkung]             
				,Target.[ressource_erzeugungsart]          = Source.[ressource_erzeugungsart]         
				,Target.[nennleistung_kw_abgabe]           = Source.[nennleistung_kw_abgabe]          
				,Target.[nennleistung_kw_aufnahme]         = Source.[nennleistung_kw_aufnahme]        
				,Target.[speicherkapazitaet_kwh]           = Source.[speicherkapazitaet_kwh]          
				,Target.[stromverbrauchsart]               = Source.[stromverbrauchsart]              
				,Target.[waermenutzung]                    = Source.[waermenutzung]                   
				,Target.[faellt_unter_enwg14a]             = Source.[faellt_unter_enwg14a]            
				,Target.[inbetriebnahme_nach_2023]         = Source.[inbetriebnahme_nach_2023]        
				,Target.[einordnung_enwg_vor2024]          = Source.[einordnung_enwg_vor2024]         
				,Target.[weitere_technische_einrichtungen] = Source.[weitere_technische_einrichtungen]
				,Target.[ressource_gueltig_ab]             = Source.[ressource_gueltig_ab]            
				,Target.[ressource_gueltig_bis]            = Source.[ressource_gueltig_bis]      
				,Target.[geaendert_am] = getdate()
				,Target.delta = 'Geändert'


		WHEN NOT MATCHED BY TARGET THEN
			----- INSERT, weil noch nicht vorhanden -----
			INSERT (
				[abnahmestelle_straße]
				,[abnahmestelle_hausnummer]
				,[abnahmestelle_hausnummer_zusatz]
				,[abnahmestelle_plz]
				,[abnahmestelle_ort]
				,[nelo]
				,[melo]
				,[malo_bezug]
				,[malo_einspeisung]
				,[id_ressource]
				,[ressource_nutzungsart]
				,[ressource_bemerkung]
				,[ressource_erzeugungsart]
				,[nennleistung_kw_abgabe]
				,[nennleistung_kw_aufnahme]
				,[speicherkapazitaet_kwh]
				,[stromverbrauchsart]
				,[waermenutzung]
				,[faellt_unter_enwg14a]
				,[inbetriebnahme_nach_2023]
				,[einordnung_enwg_vor2024]
				,[weitere_technische_einrichtungen]
				,[ressource_gueltig_ab]
				,[ressource_gueltig_bis]
				,delta
			)
			VALUES (
				 Source.[abnahmestelle_straße]
				,Source.[abnahmestelle_hausnummer]
				,Source.[abnahmestelle_hausnummer_zusatz]
				,Source.[abnahmestelle_plz]
				,Source.[abnahmestelle_ort]
				,Source.[nelo]
				,Source.[melo]
				,Source.[malo_bezug]
				,Source.[malo_einspeisung]
				,Source.[id_ressource]
				,Source.[ressource_nutzungsart]
				,Source.[ressource_bemerkung]
				,Source.[ressource_erzeugungsart]
				,Source.[nennleistung_kw_abgabe]
				,Source.[nennleistung_kw_aufnahme]
				,Source.[speicherkapazitaet_kwh]
				,Source.[stromverbrauchsart]
				,Source.[waermenutzung]
				,Source.[faellt_unter_enwg14a]
				,Source.[inbetriebnahme_nach_2023]
				,Source.[einordnung_enwg_vor2024]
				,Source.[weitere_technische_einrichtungen]
				,Source.[ressource_gueltig_ab]
				,Source.[ressource_gueltig_bis]
				,'Neu'
			)
				
		WHEN NOT MATCHED BY SOURCE and Target.geloescht_am is null THEN
			-- Datensatz nicht mehr gültig setzen wenn vorher noch nicht passiert 
			UPDATE	SET
				Target.geloescht_am = getdate()
				,Target.[geaendert_am] = getdate()
				,delta = 'Gelöscht'
		;


		-- Pflegehinweis für [mart_technische_doku].[caigos_technische_ressourcen_wilken]
		-- Wilken: Mehrere Nelos an einer Abnahmestelle
		-------------------------------------------------------------------------------------------------
		WITH doublette as (

			select 
				[abnahmestelle_straße]
				,[abnahmestelle_hausnummer]
				,[abnahmestelle_hausnummer_zusatz]
				,[abnahmestelle_plz]
				,[abnahmestelle_ort]
			from
				[mart_technische_doku].[caigos_technische_ressourcen_wilken]
			group by
				[abnahmestelle_straße]
				,[abnahmestelle_hausnummer]
				,[abnahmestelle_hausnummer_zusatz]
				,[abnahmestelle_plz]
				,[abnahmestelle_ort]
			having  
				count(distinct nelo) > 1
		)
		MERGE INTO [mart_technische_doku].[caigos_technische_ressourcen_wilken]	AS	Target
		USING
		(
			----- QUELLE -----

			select 
				id_ressource,
				'Wilken: Mehrere Nelos an einer Abnahmestelle' as Pflegehinweis
			from 
				[mart_technische_doku].[caigos_technische_ressourcen_wilken] q
			
			join
				doublette d
			on
				q.[abnahmestelle_straße] = d.[abnahmestelle_straße]
				and q.[abnahmestelle_hausnummer] = d.[abnahmestelle_hausnummer]
				and q.[abnahmestelle_hausnummer_zusatz] = d.[abnahmestelle_hausnummer_zusatz]
				and q.[abnahmestelle_plz] = d.[abnahmestelle_plz]
				and q.[abnahmestelle_ort] = d.[abnahmestelle_ort]
			

			----- QUELLE -----
		)
		AS Source	ON		
		
			Source.id_ressource = Target.id_ressource

		WHEN MATCHED and Target.geloescht_am is null THEN 

			----- UPDATE Pflegehinweis und Delta -----
			UPDATE	SET 
                          
				Target.[geaendert_am] = getdate()
				,Target.delta = case when isnull(Target.delta,'') = '' then 'Geändert' end
				,Target.Pflegehinweis = case 
											when isnull(Target.Pflegehinweis,'') = '' 
											then source.Pflegehinweis 
											else Target.Pflegehinweis + '; ' + source.Pflegehinweis 
										end
		;


		-- [mart_technische_doku].[caigos_nelos_wilken]  Ohne Technische Ressourcen
		-- In Ziel mergen dabei nicht ehr vorhandene Datensätze im Ziel markiere
		-- Nelos ohne technische Ressourcen von Wilken haben teilweise doppelte nelos, daher werden diese hier gefiltert, damit der Merge funktioniert
		---------------------------------------------------------------------------------------------------------------------------------------------------
		update [mart_technische_doku].[caigos_nelos_wilken]
		set delta = '',
			pflegehinweis = '';


		WITH doublette as (
			select 
				nelo
			from
				stage.[wilken_nelos_ohne_technische_ressourcen]
			group by
				nelo
			having count(*) > 1
		),
		TargetRows AS 
		(
			----- ZIEL -----
			select 
				[abnahmestelle_straße]
				,[abnahmestelle_hausnummer]
				,[abnahmestelle_hausnummer_zusatz]
				,[abnahmestelle_plz]
				,[abnahmestelle_ort]
				,[nelo]
				,[erstellt_am]
				,[geaendert_am]
				,[geloescht_am]
				,delta
				,CHECKSUM(
					[abnahmestelle_straße]
					,[abnahmestelle_hausnummer]
					,[abnahmestelle_hausnummer_zusatz]
					,[abnahmestelle_plz]
					,[abnahmestelle_ort]
					,[nelo]

				) as [checksum]
			  from 
				[mart_technische_doku].[caigos_nelos_wilken] 

	
		)
		MERGE INTO TargetRows	AS	Target
		USING
		(
			----- QUELLE -----

			select 
				[abnahmestelle_straße]
				,[abnahmestelle_hausnummer]
				,[abnahmestelle_hausnummer_zusatz]
				,[abnahmestelle_plz]
				,[abnahmestelle_ort]
				,[nelo]

				,CHECKSUM(
					[abnahmestelle_straße]
					,[abnahmestelle_hausnummer]
					,[abnahmestelle_hausnummer_zusatz]
					,[abnahmestelle_plz]
					,[abnahmestelle_ort]
					,[nelo]

				) as [checksum]
			from 
				stage.wilken_nelos_ohne_technische_ressourcen
			where
				nelo not in (select nelo from doublette) -- doppelte Ressource nicht mergen sondern manuell prüfen

			----- QUELLE -----
		)
		AS Source	ON		
		
			Source.[nelo] = Target.[nelo]



		WHEN MATCHED AND Target.[checksum] <> Source.[checksum] and Target.geloescht_am is null THEN

			----- UPDATE, weil schon vorhanden -----
			UPDATE	SET 
				 Target.[abnahmestelle_straße]             = Source.[abnahmestelle_straße]            
				,Target.[abnahmestelle_hausnummer]         = Source.[abnahmestelle_hausnummer]        
				,Target.[abnahmestelle_hausnummer_zusatz]  = Source.[abnahmestelle_hausnummer_zusatz] 
				,Target.[abnahmestelle_plz]                = Source.[abnahmestelle_plz]               
				,Target.[abnahmestelle_ort]                = Source.[abnahmestelle_ort]               
				,Target.[nelo]                             = Source.[nelo]                            
			
				,Target.[geaendert_am] = getdate()
				,Target.delta = 'Geändert'


		WHEN NOT MATCHED BY TARGET THEN
			----- INSERT, weil noch nicht vorhanden -----
			INSERT (
				[abnahmestelle_straße]
				,[abnahmestelle_hausnummer]
				,[abnahmestelle_hausnummer_zusatz]
				,[abnahmestelle_plz]
				,[abnahmestelle_ort]
				,[nelo]
				,delta
			)
			VALUES (
				 Source.[abnahmestelle_straße]
				,Source.[abnahmestelle_hausnummer]
				,Source.[abnahmestelle_hausnummer_zusatz]
				,Source.[abnahmestelle_plz]
				,Source.[abnahmestelle_ort]
				,Source.[nelo]
				,'Neu'
			)
				
		WHEN NOT MATCHED BY SOURCE and Target.geloescht_am is null THEN
			-- Datensatz nicht mehr gültig setzen wenn vorher noch nicht passiert 
			UPDATE	SET
				Target.geloescht_am = getdate()
				,Target.[geaendert_am] = getdate()
				,delta = 'Gelöscht'
		;


		-- Pflegehinweis für [mart_technische_doku].[caigos_nelos_wilken]
		-- Wilken: Mehrere Nelos an einer Abnahmestelle
		-------------------------------------------------------------------------------------------------
		WITH doublette as (

				select 
					[abnahmestelle_straße]
					,[abnahmestelle_hausnummer]
					,[abnahmestelle_hausnummer_zusatz]
					,[abnahmestelle_plz]
					,[abnahmestelle_ort]
				from
					[mart_technische_doku].[caigos_nelos_wilken]
				group by
					[abnahmestelle_straße]
					,[abnahmestelle_hausnummer]
					,[abnahmestelle_hausnummer_zusatz]
					,[abnahmestelle_plz]
					,[abnahmestelle_ort]
				having count(*) > 1
		)
		MERGE INTO [mart_technische_doku].[caigos_nelos_wilken]	AS	Target
		USING
		(
			----- QUELLE -----

			select 
				nelo,
				'Wilken: Mehrere Nelos an einer Abnahmestelle' as Pflegehinweis
			from 
				[mart_technische_doku].[caigos_nelos_wilken] q
			
			join
				doublette d
			on
				q.[abnahmestelle_straße] = d.[abnahmestelle_straße]
				and q.[abnahmestelle_hausnummer] = d.[abnahmestelle_hausnummer]
				and q.[abnahmestelle_hausnummer_zusatz] = d.[abnahmestelle_hausnummer_zusatz]
				and q.[abnahmestelle_plz] = d.[abnahmestelle_plz]
				and q.[abnahmestelle_ort] = d.[abnahmestelle_ort]
			

			----- QUELLE -----
		)
		AS Source	ON		
		
			Source.[nelo] = Target.[nelo]

		WHEN MATCHED and Target.geloescht_am is null  THEN

			----- UPDATE Pflegehinweis und Delta -----
			UPDATE	SET 
                          
				Target.[geaendert_am] = getdate()
				,Target.delta = case when isnull(Target.delta,'') = '' then 'Geändert' end
				,Target.Pflegehinweis = case 
											when isnull(Target.Pflegehinweis,'') = '' 
											then source.Pflegehinweis 
											else Target.Pflegehinweis + '; ' + source.Pflegehinweis 
										end
		;

		-- Caigos Elektro Hausanschluss Adressabgleich vornehmen (In beiden Tabellen)
		-- Dabei nur die Adressen abgleichen die sich 100% abgleichen lassen (Eindeutige Adresse Nelo aus wilken, Eindeutige Adresse Hausanschluss aus Caigos)
		-- Überall dort wo noch kein Pflegehinweis vorhanden ist
		-------------------------------------------------------------------------------------------

		-- Adressabgleich für [mart_technische_doku].[caigos_nelos_wilken]
		;WITH caigos_hausanschluss as (

			select
				max(eha_id) as eha_id
				,[strasse]
				,[hausnummer]
				,[hausnummer_zusatz]
				,[plz]
				,[ort]
				,count(*) as anzahl_ha_an_adresse
			from
				[stage].[caigos_elektro_hausanschluesse] ha
			where
				eha_id <> '{00000000-0000-0000-0000-000000000000}'
			group by
				[strasse]
				,[hausnummer]
				,[hausnummer_zusatz]
				,[plz]
				,[ort]	
		), targetrows as (

			select
				*
			from
				[mart_technische_doku].[caigos_nelos_wilken]
			where
				Pflegehinweis = ''
		)
		MERGE INTO targetrows AS	Target
		USING
		(
			----- QUELLE -----

			select 
				eha_id
				,[strasse]
				,[hausnummer]
				,[hausnummer_zusatz]
				,[plz]
				,[ort]
				,case when anzahl_ha_an_adresse > 1
					then 'Caigos: Mehrere Hausanschlüsse an Adresse'
					else ''
				end	as Pflegehinweis
			from 
				caigos_hausanschluss q

			----- QUELLE -----
		)
		AS Source	ON		
		
			REPLACE(UPPER(Target.abnahmestelle_straße),' ','') = REPLACE(UPPER(Source.strasse),' ','')
			and Target.abnahmestelle_hausnummer = try_cast(Source.hausnummer as int)
			and UPPER(ISNULL(Target.abnahmestelle_hausnummer_zusatz,'')) = UPPER(Source.hausnummer_zusatz)
			and UPPER(LTRIM(RTRIM(Target.abnahmestelle_ort))) = UPPER(LTRIM(RTRIM(Source.ort)))

		WHEN MATCHED and Target.geloescht_am is null  THEN

			----- UPDATE Pflegehinweis und Delta -----
			UPDATE	SET 
                          
				Target.[geaendert_am] = getdate()
				,Target.delta = case when isnull(Target.delta,'') = '' then 'Geändert' end
				,Target.eha_id = case when Source.Pflegehinweis = '' then Source.eha_id else null end
				,Target.Pflegehinweis = case 
											when Source.Pflegehinweis = '' then Target.Pflegehinweis else
												case
													when isnull(Target.Pflegehinweis,'') = '' 
													then source.Pflegehinweis 
													else Target.Pflegehinweis + '; ' + source.Pflegehinweis 
												end
											end
		;

		-- Adressabgleich für [mart_technische_doku].[caigos_technische_ressourcen_wilken]
		;WITH caigos_hausanschluss as (

			select
				max(eha_id) as eha_id
				,[strasse]
				,[hausnummer]
				,[hausnummer_zusatz]
				,[plz]
				,[ort]
				,count(*) as anzahl_ha_an_adresse
			from
				[stage].[caigos_elektro_hausanschluesse] ha
			where
				eha_id <> '{00000000-0000-0000-0000-000000000000}'
			group by
				[strasse]
				,[hausnummer]
				,[hausnummer_zusatz]
				,[plz]
				,[ort]	
		), targetrows as (

			select
				*
			from
				[mart_technische_doku].[caigos_technische_ressourcen_wilken]
			where
				Pflegehinweis = ''
		)
		MERGE INTO targetrows AS	Target
		USING
		(
			----- QUELLE -----

			select 
				eha_id
				,[strasse]
				,[hausnummer]
				,[hausnummer_zusatz]
				,[plz]
				,[ort]
				,case when anzahl_ha_an_adresse > 1
					then 'Caigos: Mehrere Hausanschlüsse an Adresse'
					else ''
				end	as Pflegehinweis
			from 
				caigos_hausanschluss q

			----- QUELLE -----
		)
		AS Source	ON		
		
			REPLACE(UPPER(Target.abnahmestelle_straße),' ','') = REPLACE(UPPER(Source.strasse),' ','')
			and Target.abnahmestelle_hausnummer = try_cast(Source.hausnummer as int)
			and UPPER(ISNULL(Target.abnahmestelle_hausnummer_zusatz,'')) = UPPER(Source.hausnummer_zusatz)
			and UPPER(LTRIM(RTRIM(Target.abnahmestelle_ort))) = UPPER(LTRIM(RTRIM(Source.ort)))

		WHEN MATCHED and Target.geloescht_am is null  THEN

			----- UPDATE Pflegehinweis und Delta -----
			UPDATE	SET 
                          
				Target.[geaendert_am] = getdate()
				,Target.delta = case when isnull(Target.delta,'') = '' then 'Geändert' end
				,Target.eha_id = case when Source.Pflegehinweis = '' then Source.eha_id else null end
				,Target.Pflegehinweis = case 
											when Source.Pflegehinweis = '' then Target.Pflegehinweis else
												case
													when isnull(Target.Pflegehinweis,'') = '' 
													then source.Pflegehinweis 
													else Target.Pflegehinweis + '; ' + source.Pflegehinweis 
												end
											end
		;

		-- Housekeeping delta
		------------------------------------------------------------------------------

		update
			[mart_technische_doku].[caigos_nelos_wilken]
		set
			delta = case 
						when geloescht_am = cast(getdate() as date) 
						then case 
								when erstellt_am = cast(getdate() as date) 
								then 'Neu' 
								else 'Geändert' 
							end
					end
		where
			delta = ''
			and (geaendert_am = cast(getdate() as date) 
					or geloescht_am = cast(getdate() as date)
						or erstellt_am = cast(getdate() as date))

		update
			[mart_technische_doku].[caigos_technische_ressourcen_wilken]
		set
			delta = case 
						when geloescht_am = cast(getdate() as date) 
						then case 
								when erstellt_am = cast(getdate() as date) 
								then 'Neu' 
								else 'Geändert' 
							end
					end
		where
			delta = ''
			and (geaendert_am = cast(getdate() as date) 
					or geloescht_am = cast(getdate() as date)
						or erstellt_am = cast(getdate() as date))	
	
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
