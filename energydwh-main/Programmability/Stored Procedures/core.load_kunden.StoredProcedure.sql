-- Object: core.load_kunden
-- Type  : SQL_STORED_PROCEDURE



/* =============================================
-- Author:		Oliver Meyer
-- Create date: 04.06.2025
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		core.geschaeftspartner

	Die Entität ist als Slow Moving/Changing Dimension ausgelegt Alle Felder von Typ 2
	Zeitscheibe mit valid_from - valid_to ist tages scharf
	Letzter gültiger Satz je Schlüssel (id_kunde) ist AKTIV = 1	

-- Change Log

	06.02.2025	OME initial
	16.09.2025	OME Kundengruppen, kategorien und zusätzlich Rechnungsturnus


-- Test:

	exec core.[load_kunden] -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_kunden]
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

	-- create temporary table for the active records
	if object_id('tempdb..#kunden') is not null
    drop table #kunden
	
	CREATE TABLE #kunden(
		[id_kunde] [decimal](12, 0) NOT NULL,
		[id_mandant] [int] NULL,
		[kunden_nummer] [varchar](20) NOT NULL,
		[id_kundenstatus] int NOT NULL,
		[unbundling_art] [varchar](18) NOT NULL,
		[id_kundengruppe] int NOT NULL,
		[id_kundenkategorie] char(3) NOT NULL,
		[id_turnusrechnung] int not null,
		[einzugsdatum] [datetime] NOT NULL,
		[auszugsdatum] [datetime] NULL,
		[id_rolle] [decimal](19, 0) NOT NULL,
		[rollenstatus] [varchar](3) NULL,
		[id_geschaeftspartner] [decimal](19, 0) NULL,
		[geschaeftspartner_nummer] [varchar](22) NOT NULL,
		[partnerstatus] [varchar](3) NULL,
		[geschaeftspartner_name] [varchar](250) NULL,
		[geschaeftspartner_name2] [varchar](250) NULL,
		[geschaeftspartner_zusatz] [varchar](40) NULL,
		[id_person] [decimal](19, 0) NULL,
		[titel] [varchar](40) NULL,
		[anrede] [varchar](40) NULL,
		[person_vorname] [varchar](50) NULL,
		[person_name] [varchar](50) NOT NULL,
		[person_zusatz] [varchar](50) NULL,
		[geburtsdatum] [date] NULL,
		[geschlecht] [varchar](3) NULL,
		[person_typ] [varchar](1) NOT NULL,
		[strasse] [varchar](100) NULL,
		[hausnummer] [varchar](100) NULL,
		[hausnummer_zusatz] [varchar](4) NULL,
		[laendercode] [varchar](3) NULL,
		[plz] [varchar](10) NULL,
		[ort] [varchar](50) NULL,
		[ortsteil] [varchar](50) NULL,
		[gemeindeschluessel] [varchar](8) NULL,
		[email] [varchar](70) NULL,
		[telefonnummer] [varchar](30) NULL,
		[mobilnummer] [varchar](30) NULL,
		[faxnummer] [varchar](30) NULL,
		[created_at] [datetime] NOT NULL,
		[changed_at] [datetime] NOT NULL,
		[valid_from] [datetime] NOT NULL,
		[valid_to] [datetime] NOT NULL,
		[active] [int] NOT NULL
	)

	-- ctes für Quelle, Ziel und Hilfstabellen
	;WITH TargetRows AS 
	(
		----- ZIEL -----
		
		SELECT [id_kunde]
		  ,[id_mandant]
		  ,[kunden_nummer]
		  ,[id_kundenstatus]
		  ,[unbundling_art]
			,[id_kundengruppe]
			,[id_kundenkategorie]
			,[id_turnusrechnung]
		  ,[einzugsdatum]
		  ,[auszugsdatum]
		  ,[id_rolle]
		  ,[rollenstatus]
		  ,[id_geschaeftspartner]
		  ,[geschaeftspartner_nummer]
		  ,[partnerstatus]
		  ,[geschaeftspartner_name]
		  ,[geschaeftspartner_name2]
		  ,[geschaeftspartner_zusatz]
		  ,[id_person]
		  ,[titel]
		  ,[anrede]
		  ,[person_vorname]
		  ,[person_name]
		  ,[person_zusatz]
		  ,[geburtsdatum]
		  ,[geschlecht]
		  ,[person_typ]
		  ,[strasse]
		  ,[hausnummer]
		  ,[hausnummer_zusatz]
		  ,[laendercode]
		  ,[plz]
		  ,[ort]
		  ,[ortsteil]
		  ,[gemeindeschluessel]
		  ,[email]
		  ,[telefonnummer]
		  ,[mobilnummer]
		  ,[faxnummer]
		  ,[created_at]
		  ,[changed_at]
		  ,[valid_from]
		  ,[valid_to]
		  ,[active]
		  ,checksum(
			  [id_mandant]
			  ,[kunden_nummer]
			  ,[id_kundenstatus]
			  ,[unbundling_art]
			,[id_kundengruppe]
			,[id_kundenkategorie]
			,[id_turnusrechnung]
			  ,[einzugsdatum]
			  ,[auszugsdatum]
			  ,[id_rolle]
			  ,[rollenstatus]
			  ,[id_geschaeftspartner]
			  ,[geschaeftspartner_nummer]
			  ,[partnerstatus]
			  ,[geschaeftspartner_name]
			  ,[geschaeftspartner_name2]
			  ,[geschaeftspartner_zusatz]
			  ,[id_person]
			  ,[titel]
			  ,[anrede]
			  ,[person_vorname]
			  ,[person_name]
			  ,[person_zusatz]
			  ,[geburtsdatum]
			  ,[geschlecht]
			  ,[person_typ]
			  ,[strasse]
			  ,[hausnummer]
			  ,[hausnummer_zusatz]
			  ,[laendercode]
			  ,[plz]
			  ,[ort]
			  ,[ortsteil]
			  ,[gemeindeschluessel]
			  ,[email]
			  ,[telefonnummer]
			  ,[mobilnummer]
			  ,[faxnummer]
		  ) as CHECKSUM
	  FROM [core].[kunden] AS	Dim
	)

	
	-- Hier werden die Neuen Zeitscheiben von geänderten Datensätzen eingefügt (Output)
	INSERT INTO #kunden
		([id_kunde]
		,[id_mandant]
		,[kunden_nummer]
		,[id_kundenstatus]
		,[unbundling_art]
			,[id_kundengruppe]
			,[id_kundenkategorie]
			,[id_turnusrechnung]
		,[einzugsdatum]
		,[auszugsdatum]
		,[id_rolle]
		,[rollenstatus]
		,[id_geschaeftspartner]
		,[geschaeftspartner_nummer]
		,[partnerstatus]
		,[geschaeftspartner_name]
		,[geschaeftspartner_name2]
		,[geschaeftspartner_zusatz]
		,[id_person]
		,[titel]
		,[anrede]
		,[person_vorname]
		,[person_name]
		,[person_zusatz]
		,[geburtsdatum]
		,[geschlecht]
		,[person_typ]
		,[strasse]
		,[hausnummer]
		,[hausnummer_zusatz]
		,[laendercode]
		,[plz]
		,[ort]
		,[ortsteil]
		,[gemeindeschluessel]
		,[email]
		,[telefonnummer]
		,[mobilnummer]
		,[faxnummer]
		,[created_at]
		,[changed_at]
		,[valid_from]
		,[valid_to]
		,[active])
	SELECT
		[id_kunde]
		,[id_mandant]
		,[kunden_nummer]
		,[id_kundenstatus]
		,[unbundling_art]
			,[id_kundengruppe]
			,[id_kundenkategorie]
			,[id_turnusrechnung]
		,[einzugsdatum]
		,[auszugsdatum]
		,[id_rolle]
		,[rollenstatus]
		,[id_geschaeftspartner]
		,[geschaeftspartner_nummer]
		,[partnerstatus]
		,[geschaeftspartner_name]
		,[geschaeftspartner_name2]
		,[geschaeftspartner_zusatz]
		,[id_person]
		,[titel]
		,[anrede]
		,[person_vorname]
		,[person_name]
		,[person_zusatz]
		,[geburtsdatum]
		,[geschlecht]
		,[person_typ]
		,[strasse]
		,[hausnummer]
		,[hausnummer_zusatz]
		,[laendercode]
		,[plz]
		,[ort]
		,[ortsteil]
		,[gemeindeschluessel]
		,[email]
		,[telefonnummer]
		,[mobilnummer]
		,[faxnummer]
		,[created_at]
		,[changed_at]
		,[valid_from]
		,[valid_to]
		,[active]
	FROM
	(
		MERGE INTO TargetRows	AS	Target
	
		USING
		(
			----- QUELLE -----
			SELECT			
				[id_kunde]
				,[id_mandant]
				,[kunden_nummer]
		,[id_kundenstatus]
		,[unbundling_art]
			,[id_kundengruppe]
			,[id_kundenkategorie]
			,[id_turnusrechnung]
				,[einzugsdatum]
				,[auszugsdatum]
				,[id_rolle]
				,[rollenstatus]
				,[id_geschaeftspartner]
				,[geschaeftspartner_nummer]
				,[partnerstatus]
				,[geschaeftspartner_name]
				,[geschaeftspartner_name2]
				,[geschaeftspartner_zusatz]
				,[id_person]
				,[titel]
				,[anrede]
				,[person_vorname]
				,[person_name]
				,[person_zusatz]
				,[geburtsdatum]
				,[geschlecht]
				,[person_typ]
				,[strasse]
				,[hausnummer]
				,[hausnummer_zusatz]
				,[laendercode]
				,[plz]
				,[ort]
				,[ortsteil]
				,[gemeindeschluessel]
				,[email]
				,[telefonnummer]
				,[mobilnummer]
				,[faxnummer]
				,[created_at]
				,[changed_at]
				,getdate() as valid_from
				,CONVERT([datetime],'31.12.9999',(104)) as valid_to
				,1 as active
				--
				  ,checksum(
					  [id_mandant]
					  ,[kunden_nummer]
						,[id_kundenstatus]
						,[unbundling_art]
						,[id_kundengruppe]
						,[id_kundenkategorie]
						,[id_turnusrechnung]
					  ,[einzugsdatum]
					  ,[auszugsdatum]
					  ,[id_rolle]
					  ,[rollenstatus]
					  ,[id_geschaeftspartner]
					  ,[geschaeftspartner_nummer]
					  ,[partnerstatus]
					  ,[geschaeftspartner_name]
					  ,[geschaeftspartner_name2]
					  ,[geschaeftspartner_zusatz]
					  ,[id_person]
					  ,[titel]
					  ,[anrede]
					  ,[person_vorname]
					  ,[person_name]
					  ,[person_zusatz]
					  ,[geburtsdatum]
					  ,[geschlecht]
					  ,[person_typ]
					  ,[strasse]
					  ,[hausnummer]
					  ,[hausnummer_zusatz]
					  ,[laendercode]
					  ,[plz]
					  ,[ort]
					  ,[ortsteil]
					  ,[gemeindeschluessel]
					  ,[email]
					  ,[telefonnummer]
					  ,[mobilnummer]
					  ,[faxnummer]
				  ) as CHECKSUM
			FROM
				stage.wilken_kunden) as Source
						
						
				ON	Source.id_kunde	= Target.id_kunde


		
		
		WHEN MATCHED AND Source.[CHECKSUM] != Target.[CHECKSUM] AND Target.active = 1 and Target.valid_from < Source.valid_from
		THEN UPDATE
	
			----- UPDATE, weil schon vorhanden und Es sich nicht um eine untertägige Änderung handelt-----
			----- Im Falle einer Slow Moving Dimension wird der Aktive Satz nur geändert DATUM BIS = GETDATE - 1 und Aktiv = 0
			SET 

				Target.valid_to				=	DATEADD(DAY,-1,Source.valid_from)
				,Target.active					=	0

		WHEN MATCHED AND Source.[CHECKSUM] != Target.[CHECKSUM] AND Target.active = 1 and Target.valid_from >= Source.valid_from
		THEN DELETE
	
				-- DELETE --
				-- Bei einer untertägigen Änderung der Datensätze wird nur letzte Satz genommen, also der Alte gelöscht und der neue Hinzugefügt 


		WHEN NOT MATCHED BY TARGET 
		THEN INSERT (
				----- INSERT, weil noch nicht vorhanden -----
				[id_kunde]
				,[id_mandant]
				,[kunden_nummer]
		,[id_kundenstatus]
		,[unbundling_art]
			,[id_kundengruppe]
			,[id_kundenkategorie]
			,[id_turnusrechnung]
				,[einzugsdatum]
				,[auszugsdatum]
				,[id_rolle]
				,[rollenstatus]
				,[id_geschaeftspartner]
				,[geschaeftspartner_nummer]
				,[partnerstatus]
				,[geschaeftspartner_name]
				,[geschaeftspartner_name2]
				,[geschaeftspartner_zusatz]
				,[id_person]
				,[titel]
				,[anrede]
				,[person_vorname]
				,[person_name]
				,[person_zusatz]
				,[geburtsdatum]
				,[geschlecht]
				,[person_typ]
				,[strasse]
				,[hausnummer]
				,[hausnummer_zusatz]
				,[laendercode]
				,[plz]
				,[ort]
				,[ortsteil]
				,[gemeindeschluessel]
				,[email]
				,[telefonnummer]
				,[mobilnummer]
				,[faxnummer]
				,[created_at]
				,[changed_at]
				,[valid_from]
				,[valid_to]
				,[active]
			)
			VALUES ( 
				Source.[id_kunde]
				,Source.[id_mandant]
				,Source.[kunden_nummer]
				,Source.[id_kundenstatus]
				,Source.[unbundling_art]
			,Source.[id_kundengruppe]
			,Source.[id_kundenkategorie]
			,Source.[id_turnusrechnung]
				,Source.[einzugsdatum]
				,Source.[auszugsdatum]
				,Source.[id_rolle]
				,Source.[rollenstatus]
				,Source.[id_geschaeftspartner]
				,Source.[geschaeftspartner_nummer]
				,Source.[partnerstatus]
				,Source.[geschaeftspartner_name]
				,Source.[geschaeftspartner_name2]
				,Source.[geschaeftspartner_zusatz]
				,Source.[id_person]
				,Source.[titel]
				,Source.[anrede]
				,Source.[person_vorname]
				,Source.[person_name]
				,Source.[person_zusatz]
				,Source.[geburtsdatum]
				,Source.[geschlecht]
				,Source.[person_typ]
				,Source.[strasse]
				,Source.[hausnummer]
				,Source.[hausnummer_zusatz]
				,Source.[laendercode]
				,Source.[plz]
				,Source.[ort]
				,Source.[ortsteil]
				,Source.[gemeindeschluessel]
				,Source.[email]
				,Source.[telefonnummer]
				,Source.[mobilnummer]
				,Source.[faxnummer]
				,Source.[created_at]
				,Source.[changed_at]
				,Source.[created_at] -- bei erstem insert das erstelldatum des Kunden in wilken Energy nehmen
				,Source.[valid_to]
				,1
			)
	
		OUTPUT
			Source.*, $ACTION AS MergeAction
	) MRG 
		WHERE MergeAction In ('UPDATE','DELETE')
	; 	

	/*if @verbose = 1 -- Ausgabe der neuen Rows
		select * from #kunden*/


	-- aktuelle Rows einfügen
	insert into [core].[kunden]
		([id_kunde]
		,[id_mandant]
		,[kunden_nummer]
		,[id_kundenstatus]
		,[unbundling_art]
			,[id_kundengruppe]
			,[id_kundenkategorie]
			,[id_turnusrechnung]
		,[einzugsdatum]
		,[auszugsdatum]
		,[id_rolle]
		,[rollenstatus]
		,[id_geschaeftspartner]
		,[geschaeftspartner_nummer]
		,[partnerstatus]
		,[geschaeftspartner_name]
		,[geschaeftspartner_name2]
		,[geschaeftspartner_zusatz]
		,[id_person]
		,[titel]
		,[anrede]
		,[person_vorname]
		,[person_name]
		,[person_zusatz]
		,[geburtsdatum]
		,[geschlecht]
		,[person_typ]
		,[strasse]
		,[hausnummer]
		,[hausnummer_zusatz]
		,[laendercode]
		,[plz]
		,[ort]
		,[ortsteil]
		,[gemeindeschluessel]
		,[email]
		,[telefonnummer]
		,[mobilnummer]
		,[faxnummer]
		,[created_at]
		,[changed_at]
		,[valid_from]
		,[valid_to]
		,[active])
	select
		[id_kunde]
		,[id_mandant]
		,[kunden_nummer]
		,[id_kundenstatus]
		,[unbundling_art]
			,[id_kundengruppe]
			,[id_kundenkategorie]
			,[id_turnusrechnung]
		,[einzugsdatum]
		,[auszugsdatum]
		,[id_rolle]
		,[rollenstatus]
		,[id_geschaeftspartner]
		,[geschaeftspartner_nummer]
		,[partnerstatus]
		,[geschaeftspartner_name]
		,[geschaeftspartner_name2]
		,[geschaeftspartner_zusatz]
		,[id_person]
		,[titel]
		,[anrede]
		,[person_vorname]
		,[person_name]
		,[person_zusatz]
		,[geburtsdatum]
		,[geschlecht]
		,[person_typ]
		,[strasse]
		,[hausnummer]
		,[hausnummer_zusatz]
		,[laendercode]
		,[plz]
		,[ort]
		,[ortsteil]
		,[gemeindeschluessel]
		,[email]
		,[telefonnummer]
		,[mobilnummer]
		,[faxnummer]
		,[created_at]
		,[changed_at]
		,[valid_from]
		,[valid_to]
		,[active]	
	from #kunden




	-- Housekeeping
	if object_id('tempdb..#kunden') is not null
    drop table #kunden

	
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
