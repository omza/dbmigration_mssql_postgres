-- Object: mart_technische_doku.load_caigos_elektro_adressabgleich_abnahmestellen_wilken
-- Type  : SQL_STORED_PROCEDURE




/* =============================================
-- Author:		Oliver Meyer
-- Create date: 27.05.2026
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: [mart_technische_doku].[caigos_elektro_adressabgleich_abnahmestellen_wilken]
	Die ausführung per view dauert zu lange. deshalb wird dieses Dataset auf Anfrage neu erstellt.
	Die Anfrage ist der Trigger für die manuelle Neloschnittstelle zwischen Caigos und Wilken

-- Change Log
	01.09.2026	OME initial



-- Test:
	exec [mart_technische_doku].[load_caigos_elektro_adressabgleich_abnahmestellen_wilken] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE [mart_technische_doku].[load_caigos_elektro_adressabgleich_abnahmestellen_wilken]

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
		

		-- adressabgleich caigos elektro in lokale tabelle extrahieren und index auf abgleich feld setzen

		if object_id('tempdb..#caigos_eha') is not null drop table #caigos_eha;   

		select
			[eha_id]
			,[eha_nr]
			,[eha_bez]
			,[status]
			,[strasse]
			,[hausnummer_original]
			,[hausnummer_zusatz_original]
			,[plz]
			,[ort]
			,[versorgungsbezirk]
			,[anschlussort]
			,[lageinfo]
			,[netzlokation] as caigos_nelo
			,cast(stage.adressabgleich(
				strasse,
				hausnummer_original,
				'',
				'',
				ort
			) as varchar(500)) as caigos_adrabgleich
		into
			#caigos_eha
		from
			stage.caigos_elektro_hausanschluesse with (nolock)


		create nonclustered index idx_caigos_eha_adrabgleich on #caigos_eha(caigos_adrabgleich)

		if @verbose = 1 
			select * from #caigos_eha

		-- adressabgleich abnahmestellen in lokale tabelle extrahieren und index auf abgleich feld setzen
		if object_id('tempdb..#wilken_abn') is not null drop table #wilken_abn;

		select
			[id_abn]		
			,[id_mandant]
			,[abnahmestelle_status]
			,[abnahmestelle_adresse]
			,[abnahmestelle_straße]
			,[abnahmestelle_hausnummer]
			,[abnahmestelle_hausnummer_zusatz]
			,[abnahmestelle_plz]
			,[abnahmestelle_ort]
			,[abnahmestelle_lat]
			,[abnahmestelle_lon]
			,anzahl_melos 	
			--
			,[id_netzlokation]
			,[netzlokation] as wilken_nelo
			,[lokationsbuendel_status]
			,cast(stage.adressabgleich(
				[abnahmestelle_straße],
				[abnahmestelle_hausnummer],
				[abnahmestelle_hausnummer_zusatz],
				'',
				[abnahmestelle_ort]
			) as varchar(500)) as wilken_adrabgleich
		into
			#wilken_abn
		from
			core.abnahmestellen (nolock)
		where
			id_energieart = 1 -- nur Strom

		create nonclustered index idx_wilken_abn_adrabgleich on #wilken_abn(wilken_adrabgleich)

		if @verbose = 1 
			select * from #wilken_abn


		-- Ersetze nun das Dataset caigos_elektro_adressabgleich_abnahmestellen_wilken
		--select object_id('[EnergyDWH].[mart_technische_doku].[caigos_elektro_adressabgleich_abnahmestellen_wilken]')
		if object_id('[EnergyDWH].[mart_technische_doku].[caigos_elektro_adressabgleich_abnahmestellen_wilken]') is not null 
			drop table [EnergyDWH].[mart_technische_doku].[caigos_elektro_adressabgleich_abnahmestellen_wilken];

		select
			eha.*
			,abn.*

		into
			[mart_technische_doku].[caigos_elektro_adressabgleich_abnahmestellen_wilken]

		from
			#caigos_eha eha	

		full outer join
			#wilken_abn abn on eha.caigos_adrabgleich = abn.wilken_adrabgleich

	
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

	-- Housekeeping
	if object_id('tempdb..#caigos_eha') is not null drop table #caigos_eha; 
	if object_id('tempdb..#wilken_abn') is not null drop table #wilken_abn;

	--	---------------------------------------------------
	IF @verbose = 1 -- Exec Log Detail with SP Name
		INSERT INTO [admin].[transform_log_detail] ([transform_job_id],[transform_routine],[transform_message])
		VALUES (@transform_job_id, @SP_NAME, 'Ende')


END;

GO
