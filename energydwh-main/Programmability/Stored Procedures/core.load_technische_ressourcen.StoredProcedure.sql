-- Object: core.load_technische_ressourcen
-- Type  : SQL_STORED_PROCEDURE
/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: [core].[technische_ressourcen]

-- Change Log

	13.07.2026	OME initial
	


-- Test:

	exec core.load_technische_ressourcen -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_technische_ressourcen]
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

	WITH TargetRows AS 
	(
		----- ZIEL -----
		SELECT 
			id_mandant
			,[id_ressource]
			,[ressourcen_nummer]
			,[id_abn]
			,[id_zp]
			,[id_malo_bezug]
			,[id_malo_einspeisung]
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
			,created_at
			,changed_at

			,CHECKSUM(
				[ressourcen_nummer]
				,[id_abn]
				,[id_zp]
				,[id_malo_bezug]
				,[id_malo_einspeisung]
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
				,created_at
				,changed_at
			) AS CHECKSUM
		  FROM 
			[core].[technische_ressourcen]	AS	Dim


	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		SELECT DISTINCT
			id_mandant
			,[id_wilken_ressource] as id_ressource
			,[id_ressource] as ressourcen_nummer
			,[id_abn]
			,[id_zp]
			,[id_malo_bezug]
			,[id_malo_einspeisung]
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
			,cast(isnull([ressource_gueltig_bis],'9999-12-31') as date) as [ressource_gueltig_bis]
			,created_at
			,changed_at
			
			,CHECKSUM(
				[id_ressource]
				,[id_abn]
				,[id_zp]
				,[id_malo_bezug]
				,[id_malo_einspeisung]
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
				,cast(isnull([ressource_gueltig_bis],'9999-12-31') as date)
				,created_at
				,changed_at
			) AS CHECKSUM
		  FROM 
			[stage].[wilken_technische_ressourcen]
		 --where
			--id_zp is not null

		----- QUELLE -----
	)
	AS 
		Source
	ON		
		Source.[id_ressource] = Target.[id_ressource]
		and Source.id_mandant = Target.[id_mandant]


	WHEN MATCHED AND Source.[CHECKSUM] != Target.[CHECKSUM] THEN

		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 

			Target.[ressourcen_nummer]                            = Source.[ressourcen_nummer]
			,Target.[id_abn]                                       = Source.[id_abn]
			,Target.[id_zp]                                        = Source.[id_zp]
			,Target.[id_malo_bezug]                                = Source.[id_malo_bezug]
			,Target.[id_malo_einspeisung]                          = Source.[id_malo_einspeisung]
			,Target.[ressource_nutzungsart]                        = Source.[ressource_nutzungsart]
			,Target.[ressource_bemerkung]                          = Source.[ressource_bemerkung]
			,Target.[ressource_erzeugungsart]                      = Source.[ressource_erzeugungsart]
			,Target.[nennleistung_kw_abgabe]                       = Source.[nennleistung_kw_abgabe]
			,Target.[nennleistung_kw_aufnahme]                     = Source.[nennleistung_kw_aufnahme]
			,Target.[speicherkapazitaet_kwh]                       = Source.[speicherkapazitaet_kwh]
			,Target.[stromverbrauchsart]                           = Source.[stromverbrauchsart]
			,Target.[waermenutzung]                                = Source.[waermenutzung]
			,Target.[faellt_unter_enwg14a]                         = Source.[faellt_unter_enwg14a]
			,Target.[inbetriebnahme_nach_2023]                     = Source.[inbetriebnahme_nach_2023]
			,Target.[einordnung_enwg_vor2024]                      = Source.[einordnung_enwg_vor2024]
			,Target.[weitere_technische_einrichtungen]             = Source.[weitere_technische_einrichtungen]
			,Target.[ressource_gueltig_ab]                         = Source.[ressource_gueltig_ab]
			,Target.[ressource_gueltig_bis]                        = Source.[ressource_gueltig_bis]
			,Target.created_at                                     = Source.created_at
			,Target.changed_at                                     = Source.changed_at	

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			id_mandant
			,[id_ressource]
			,[ressourcen_nummer]
			,[id_abn]
			,[id_zp]
			,[id_malo_bezug]
			,[id_malo_einspeisung]
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
			,created_at
			,changed_at
		)
		VALUES (
			Source.id_mandant
			,Source.[id_ressource]
			,Source.[ressourcen_nummer]
			,Source.[id_abn]
			,Source.[id_zp]
			,Source.[id_malo_bezug]
			,Source.[id_malo_einspeisung]
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
			,Source.created_at
			,Source.changed_at
		)

	;
		
	
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
