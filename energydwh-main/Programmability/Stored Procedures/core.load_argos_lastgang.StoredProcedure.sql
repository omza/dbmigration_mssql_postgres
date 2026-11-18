-- Object: core.load_argos_lastgang
-- Type  : SQL_STORED_PROCEDURE

/* =============================================
-- Author:		Oliver Meyer
-- Create date: 04.02.2025
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		stage.argos_file_import
		core.messwerte_lastgang_15min
		core.messwerte_lastgang_gastag
	

-- Change Log

	04.02.2025	OME initial
	27.03.2025	OMe	Wertstatus ausgelagert
	20.10.2025	OMe	Fix für Zeitraumkonversion bei Lastgangdateien die mehr als einen Tag umspannen (immer der Anfang genommen) 


-- Test:

	exec core.[load_argos_lastgang] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_argos_lastgang]
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

	/*
		Pflege Argos File Import Tabelle
	*/
	INSERT INTO [stage].[argos_file_import]
			   ([load_log_id]
			   ,[filename]
			   ,[Kunden_Name]
			   ,[Kunden_Nummer]
			   ,[Meteringcode]
			   ,[Zaehlernummer]
			   ,[Kanal]
			   ,[OBIS]
			   ,[Zeitraum]
			   ,[Wandlerfaktor]
			   ,[Raster_Minuten]
			   ,[Messeinheit]
			   ,[Anzahl_Werte]
			   ,[kWh])
		select 
			piv.load_log_id, 
			piv.filename, 
			LTRIM(RTRIM([Kunde:]))	AS Kunden_Name, 
			LTRIM(RTRIM([Kundennummer:])) AS Kunden_Nummer, 
			LTRIM(RTRIM([Zählpunktbez.:])) as Meteringcode, 
			LTRIM(RTRIM([MessgeräteNr:])) AS Zaehlernummer, 
			CAST([Kanal:] AS INT) AS Kanal, 
			LTRIM(RTRIM([OBIS-Kennzahl:])) as OBIS, 
			TRY_CONVERT(date,left([Zeitraum:],10),104) AS Zeitraum, 
			CAST([Faktor:] as INT) as Wandlerfaktor , 
			CAST([Meßperiode:] as Int)/60 as Raster_Minuten, 
			LTRIM(RTRIM([Einheit:])) Messeinheit, 
			CAST([Daten:] as INT) Anzahl_Werte, 
			CAST(REPLACE([Energie:],',','.') as DECIMAL(18,3)) as kWh
		from
			(
			  select 
				filename, load_log_id, last, Zeit
			  from [raw].[argos_lastgang]
			) d
			pivot
			(
			  max(last)
			  for Zeit in ([Kunde:], [Kundennummer:], [Zählpunktbez.:], [MessgeräteNr:], [Kanal:], [OBIS-Kennzahl:], [Zeitraum:], [Faktor:], [Meßperiode:], [Einheit:], [Daten:], [Energie:])
			) piv
		left join 
			[stage].[argos_file_import] imp ON piv.load_log_id = imp.load_log_id and piv.filename = imp.filename
		where
			imp.filename is null

	
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
