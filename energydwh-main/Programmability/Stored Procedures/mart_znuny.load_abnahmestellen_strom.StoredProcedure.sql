-- Object: mart_znuny.load_abnahmestellen_strom
-- Type  : SQL_STORED_PROCEDURE




/* =============================================
-- Author:		Oliver Meyer
-- Create date: 26.03.2026
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		mart_znuny.abnahmestellen_strom 
	

-- Change Log

	26.03.2026	OME initial
	02.04.2026	OME	Bei gültig bis auch änderungsdatum setzen


-- Test:

	exec mart_znuny.[load_abnahmestellen_strom] -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[mart_znuny].[load_abnahmestellen_strom]
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
		IF OBJECT_ID(N'tempdb..#tmp_abnahmestellen_strom') IS NOT NULL
			drop table #tmp_abnahmestellen_strom

		select * into #tmp_abnahmestellen_strom from mart_znuny.abnahmestellen_strom_aktuell


		-- Fehlende Verträge nachtragen
		update a
		set
			vertragsnummer = v.vertragsnummer
			,produkt = p.produkt
			,variante = p.variante

	
		from 
			#tmp_abnahmestellen_strom a

	
		join
			core.vertraege v 
		on
			v.id_mandant =  1 -- swnor
			and v.id_energieart = 1 --strom
			and a.einspeiser = 0
			and a.vertragsnummer is null
			and a.kunden_nummer = left(v.vertragsnummer,6)
			and getdate() between v.vertragsbeginn and v.vertragsende

		join
			core.produkte p on v.id_produkt = p.id_produkt and v.id_produktvariante = p.id_produktvariante and  p.id_energieart = 1 -- strom

		-- In Ziel mergen dabei nicht ehr vorhandene Datensätze im Ziel markiere
		;WITH TargetRows AS 
		(
			----- ZIEL -----
			select
				[melo]
				,[malo]
				,[einspeiser]
				,[strasse]
				,[hausnummer]
				,[hausnummer_zusatz]
				,[plz]
				,[ort]
				,[fallgruppe]
				,[kunden_nummer]
				,[person_vorname]
				,[person_name]
				,[telefonnummer]
				,[mobilnummer]
				,[email]
				,[vertragsnummer]
				,[produkt]
				,[variante]
				,[zaehlernummer]
				,[geraetetyp]
				,[standardgeraetetyp]
				,[nenngroesse]
				,[eichung]
				,[naechste_eichung]
				,[zaehlerpin]
				,[beziehungsart]
				,[gateway]
				,[gateway_einbau]
				,[gueltig_bis]
				,[geaendert_am]
				,checksum(
					[melo]
					,[malo]
					,[einspeiser]
					,[strasse]
					,[hausnummer]
					,[hausnummer_zusatz]
					,[plz]
					,[ort]
					,[fallgruppe]
					,[kunden_nummer]
					,[person_vorname]
					,[person_name]
					,[telefonnummer]
					,[mobilnummer]
					,[email]
					,[vertragsnummer]
					,[produkt]
					,[variante]
					,[zaehlernummer]
					,[geraetetyp]
					,[standardgeraetetyp]
					,[nenngroesse]
					,[eichung]
					,[naechste_eichung]
					,[zaehlerpin]
					,[beziehungsart]
					,[gateway]
					,[gateway_einbau]
				) as [checksum]
			FROM 
				mart_znuny.abnahmestellen_strom  
			AS	Dim
		)
		MERGE INTO TargetRows	AS	Target
		USING
		(
			----- QUELLE -----

			select 
				[melo]
				,[malo]
				,[einspeiser]
				,[strasse]
				,[hausnummer]
				,[hausnummer_zusatz]
				,[plz]
				,[ort]
				,[fallgruppe]
				,[kunden_nummer]
				,[person_vorname]
				,[person_name]
				,[telefonnummer]
				,[mobilnummer]
				,[email]
				,[vertragsnummer]
				,[produkt]
				,[variante]
				,[zaehlernummer]
				,[geraetetyp]
				,[standardgeraetetyp]
				,[nenngroesse]
				,[eichung]
				,[naechste_eichung]
				,[zaehlerpin]
				,[beziehungsart]
				,[gateway]
				,[gateway_einbau]
				,checksum(
					[melo]
					,[malo]
					,[einspeiser]
					,[strasse]
					,[hausnummer]
					,[hausnummer_zusatz]
					,[plz]
					,[ort]
					,[fallgruppe]
					,[kunden_nummer]
					,[person_vorname]
					,[person_name]
					,[telefonnummer]
					,[mobilnummer]
					,[email]
					,[vertragsnummer]
					,[produkt]
					,[variante]
					,[zaehlernummer]
					,[geraetetyp]
					,[standardgeraetetyp]
					,[nenngroesse]
					,[eichung]
					,[naechste_eichung]
					,[zaehlerpin]
					,[beziehungsart]
					,[gateway]
					,[gateway_einbau]
				) as [checksum]
			from 
				#tmp_abnahmestellen_strom

			----- QUELLE -----
		)
		AS Source	ON		
		
			Source.[melo] = Target.[melo]
			and Source.[malo] = Target.[malo]
			and Source.[kunden_nummer] = Target.[kunden_nummer]
			and Source.[zaehlernummer] = Target.[zaehlernummer]

		WHEN MATCHED AND Target.[checksum] <> Source.[checksum] THEN

			----- UPDATE, weil schon vorhanden -----
			UPDATE	SET 
				Target.[einspeiser]                       = Source.[einspeiser]
				,Target.[strasse]                          = Source.[strasse]
				,Target.[hausnummer]                       = Source.[hausnummer]
				,Target.[hausnummer_zusatz]                = Source.[hausnummer_zusatz]
				,Target.[plz]                              = Source.[plz]
				,Target.[ort]                              = Source.[ort]
				,Target.[fallgruppe]                       = Source.[fallgruppe]
				,Target.[person_vorname]                   = Source.[person_vorname]
				,Target.[person_name]                      = Source.[person_name]
				,Target.[telefonnummer]                    = Source.[telefonnummer]
				,Target.[mobilnummer]                      = Source.[mobilnummer]
				,Target.[email]                            = Source.[email]
				,Target.[vertragsnummer]                   = Source.[vertragsnummer]
				,Target.[produkt]                          = Source.[produkt]
				,Target.[variante]                         = Source.[variante]
				,Target.[geraetetyp]                       = Source.[geraetetyp]
				,Target.[standardgeraetetyp]               = Source.[standardgeraetetyp]
				,Target.[nenngroesse]                      = Source.[nenngroesse]
				,Target.[eichung]                          = Source.[eichung]
				,Target.[naechste_eichung]                 = Source.[naechste_eichung]
				,Target.[zaehlerpin]                       = Source.[zaehlerpin]
				,Target.[beziehungsart]                    = Source.[beziehungsart]
				,Target.[gateway]                          = Source.[gateway]
				,Target.[gateway_einbau]                   = Source.[gateway_einbau]	
				,Target.[geaendert_am] = getdate()



		WHEN NOT MATCHED BY TARGET THEN
			----- INSERT, weil noch nicht vorhanden -----
			INSERT (
				[melo]
				,[malo]
				,[einspeiser]
				,[strasse]
				,[hausnummer]
				,[hausnummer_zusatz]
				,[plz]
				,[ort]
				,[fallgruppe]
				,[kunden_nummer]
				,[person_vorname]
				,[person_name]
				,[telefonnummer]
				,[mobilnummer]
				,[email]
				,[vertragsnummer]
				,[produkt]
				,[variante]
				,[zaehlernummer]
				,[geraetetyp]
				,[standardgeraetetyp]
				,[nenngroesse]
				,[eichung]
				,[naechste_eichung]
				,[zaehlerpin]
				,[beziehungsart]
				,[gateway]
				,[gateway_einbau]
				,[gueltig_bis]
				,[geaendert_am]
			)
			VALUES (
				 Source.[melo]
				,Source.[malo]
				,Source.[einspeiser]
				,Source.[strasse]
				,Source.[hausnummer]
				,Source.[hausnummer_zusatz]
				,Source.[plz]
				,Source.[ort]
				,Source.[fallgruppe]
				,Source.[kunden_nummer]
				,Source.[person_vorname]
				,Source.[person_name]
				,Source.[telefonnummer]
				,Source.[mobilnummer]
				,Source.[email]
				,Source.[vertragsnummer]
				,Source.[produkt]
				,Source.[variante]
				,Source.[zaehlernummer]
				,Source.[geraetetyp]
				,Source.[standardgeraetetyp]
				,Source.[nenngroesse]
				,Source.[eichung]
				,Source.[naechste_eichung]
				,Source.[zaehlerpin]
				,Source.[beziehungsart]
				,Source.[gateway]
				,Source.[gateway_einbau]
				,convert(date, '31.12.9999', 104) -- gueltig_bis
				,getdate() -- geaendert/neu am
			)
				
		WHEN NOT MATCHED BY SOURCE and Target.gueltig_bis = convert(date, '31.12.9999', 104) THEN
			-- Datensatz nicht mehr gültig setzen wenn vorher noch nicht passiert 
			UPDATE	SET
				Target.gueltig_bis = dateadd(day,-1,getdate())
				,Target.[geaendert_am] = getdate()

		;


		-- housekeeping
		IF OBJECT_ID(N'tempdb..#tmp_abnahmestellen_strom') IS NOT NULL
			drop table #tmp_abnahmestellen_strom

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
