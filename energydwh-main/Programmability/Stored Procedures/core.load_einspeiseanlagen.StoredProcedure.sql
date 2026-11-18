-- Object: core.load_einspeiseanlagen
-- Type  : SQL_STORED_PROCEDURE




/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		core.einspeiseanlagen
	

-- Change Log

	22.09.2026	OME initial
	23.09.2026	OMe	Installierte Leistung und Änderungstyp dazu
	


-- Test:

	exec core.[load_einspeiseanlagen] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_einspeiseanlagen]
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

	;WITH TargetRows AS 
	(
		----- ZIEL -----

		select 
			[id_einspeiseanlage]
			,[id_mandant]
			,[id_zp]
			,[id_zp_einspeisezaehlpunkt]
			,[einspeisezaehlpunkt_gueltig_ab]
			,[id_abn]
			,[einspeiseanlage]
			,[energietraeger]
			,[id_status]
			,[status]
			,[storniert_am]
			,[id_einspeiseart]
			,[einspeiseart]
			-- 23.09.26
			,[einspeiseanlage_aenderungstyp]
			,[installierte_leistung]

			,[bnetza_eeg_schluessel]
			,[bnetzameldedatum]
			,[bnetza_aso_nr]
			,[marktstammdatenregister_nummer]
			,[marktstammdatenregister_registriert_am]
			,[id_nvp]
			,[netzverknuepfungspunkt]
			,[nvp_gueltig_ab]
			,[inbetriebnahme]
			,[stilllegungsdatum]
			,[netzzugang]
			,[netzabgang]
			,[aufnahme_dauerbetrieb]
			,[stromerzeugungseinheit_mastnr_nummer]
			,[stromerzeugungseinheit_mastnr_registriert_am]
			,[stromerzeugungseinheit_gueltig_ab]
			,[id_ressource]
			,[created_at]
			,[changed_at]

			,checksum(
				[id_mandant]
				,[id_zp]
				,[id_zp_einspeisezaehlpunkt]
				,[einspeisezaehlpunkt_gueltig_ab]
				,[id_abn]
				,[einspeiseanlage]
				,[energietraeger]
				,[id_status]
				,[status]
				,[storniert_am]
				,[id_einspeiseart]
				,[einspeiseart]
				-- 23.09.26
				,[einspeiseanlage_aenderungstyp]
				,[installierte_leistung]
				,[bnetza_eeg_schluessel]
				,[bnetzameldedatum]
				,[bnetza_aso_nr]
				,[marktstammdatenregister_nummer]
				,[marktstammdatenregister_registriert_am]
				,[id_nvp]
				,[netzverknuepfungspunkt]
				,[nvp_gueltig_ab]
				,[inbetriebnahme]
				,[stilllegungsdatum]
				,[netzzugang]
				,[netzabgang]
				,[aufnahme_dauerbetrieb]
				,[stromerzeugungseinheit_mastnr_nummer]
				,[stromerzeugungseinheit_mastnr_registriert_am]
				,[stromerzeugungseinheit_gueltig_ab]
				,[id_ressource]
				,[created_at]
				,[changed_at]

			) as [checksum]
		from 
			[core].[einspeiseanlagen]



	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		select 
			[id_einspeiseanlage]
			,[id_mandant]
			,[id_zp]
			,[id_zp_einspeisezaehlpunkt]
			,[einspeisezaehlpunkt_gueltig_ab]
			,[id_abn]
			,[einspeiseanlage]
			,[energietraeger]
			,[id_status]
			,[status]
			,[storniert_am]
			,[id_einspeiseart]
			,[einspeiseart]
			-- 23.09.26
			,[einspeiseanlage_aenderungstyp]
			,[installierte_leistung]

			,[bnetza_eeg_schluessel]
			,[bnetzameldedatum]
			,[bnetza_aso_nr]
			,[marktstammdatenregister_nummer]
			,[marktstammdatenregister_registriert_am]
			,[id_nvp]
			,[netzverknuepfungspunkt]
			,[nvp_gueltig_ab]
			,[inbetriebnahme]
			,[stilllegungsdatum]
			,[netzzugang]
			,[netzabgang]
			,[aufnahme_dauerbetrieb]
			,[stromerzeugungseinheit_mastnr_nummer]
			,[stromerzeugungseinheit_mastnr_registriert_am]
			,[stromerzeugungseinheit_gueltig_ab]
			,[id_ressource]
			,[created_at]
			,[changed_at]

			,checksum(
				[id_mandant]
				,[id_zp]
				,[id_zp_einspeisezaehlpunkt]
				,[einspeisezaehlpunkt_gueltig_ab]
				,[id_abn]
				,[einspeiseanlage]
				,[energietraeger]
				,[id_status]
				,[status]
				,[storniert_am]
				,[id_einspeiseart]
				,[einspeiseart]
				-- 23.09.26
				,[einspeiseanlage_aenderungstyp]
				,[installierte_leistung]
				,[bnetza_eeg_schluessel]
				,[bnetzameldedatum]
				,[bnetza_aso_nr]
				,[marktstammdatenregister_nummer]
				,[marktstammdatenregister_registriert_am]
				,[id_nvp]
				,[netzverknuepfungspunkt]
				,[nvp_gueltig_ab]
				,[inbetriebnahme]
				,[stilllegungsdatum]
				,[netzzugang]
				,[netzabgang]
				,[aufnahme_dauerbetrieb]
				,[stromerzeugungseinheit_mastnr_nummer]
				,[stromerzeugungseinheit_mastnr_registriert_am]
				,[stromerzeugungseinheit_gueltig_ab]
				,[id_ressource]
				,[created_at]
				,[changed_at]

			) as [checksum]
		from 			
			[stage].[wilken_einspeiseanlagen] 

		----- QUELLE -----
	)
	AS Source	ON	 Source.[id_einspeiseanlage] = Target.[id_einspeiseanlage]

	WHEN MATCHED AND Source.CHECKSUM != Target.CHECKSUM THEN

		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 

			Target.[id_mandant]                                         =        Source.[id_mandant]
			,Target.[id_zp]                                              =        Source.[id_zp]
			,Target.[id_zp_einspeisezaehlpunkt]                          =        Source.[id_zp_einspeisezaehlpunkt]
			,Target.[einspeisezaehlpunkt_gueltig_ab]                     =        Source.[einspeisezaehlpunkt_gueltig_ab]
			,Target.[id_abn]                                             =        Source.[id_abn]
			,Target.[einspeiseanlage]                                    =        Source.[einspeiseanlage]
			,Target.[energietraeger]                                     =        Source.[energietraeger]
			,Target.[id_status]                                          =        Source.[id_status]
			,Target.[status]                                             =        Source.[status]
			,Target.[storniert_am]                                       =        Source.[storniert_am]
			,Target.[id_einspeiseart]                                    =        Source.[id_einspeiseart]
			,Target.[einspeiseart]                                       =        Source.[einspeiseart]
			-- 23.09.26
			,Target.[einspeiseanlage_aenderungstyp]						 =        Source.[einspeiseanlage_aenderungstyp]
			,Target.[installierte_leistung]								 =        Source.[installierte_leistung]

			,Target.[bnetza_eeg_schluessel]                              =        Source.[bnetza_eeg_schluessel]
			,Target.[bnetzameldedatum]                                   =        Source.[bnetzameldedatum]
			,Target.[bnetza_aso_nr]                                      =        Source.[bnetza_aso_nr]
			,Target.[marktstammdatenregister_nummer]                     =        Source.[marktstammdatenregister_nummer]
			,Target.[marktstammdatenregister_registriert_am]             =        Source.[marktstammdatenregister_registriert_am]
			,Target.[id_nvp]                                             =        Source.[id_nvp]
			,Target.[netzverknuepfungspunkt]                             =        Source.[netzverknuepfungspunkt]
			,Target.[nvp_gueltig_ab]                                     =        Source.[nvp_gueltig_ab]
			,Target.[inbetriebnahme]                                     =        Source.[inbetriebnahme]
			,Target.[stilllegungsdatum]                                  =        Source.[stilllegungsdatum]
			,Target.[netzzugang]                                         =        Source.[netzzugang]
			,Target.[netzabgang]                                         =        Source.[netzabgang]
			,Target.[aufnahme_dauerbetrieb]                              =        Source.[aufnahme_dauerbetrieb]
			,Target.[stromerzeugungseinheit_mastnr_nummer]               =        Source.[stromerzeugungseinheit_mastnr_nummer]
			,Target.[stromerzeugungseinheit_mastnr_registriert_am]       =        Source.[stromerzeugungseinheit_mastnr_registriert_am]
			,Target.[stromerzeugungseinheit_gueltig_ab]                  =        Source.[stromerzeugungseinheit_gueltig_ab]
			,Target.[id_ressource]                                       =        Source.[id_ressource]
			,Target.[created_at]                                         =        Source.[created_at]
			,Target.[changed_at]                                         =        Source.[changed_at]



	WHEN NOT MATCHED BY TARGET THEN

		----- INSERT, weil noch nicht vorhanden -----


		INSERT (
			[id_einspeiseanlage]
			,[id_mandant]
			,[id_zp]
			,[id_zp_einspeisezaehlpunkt]
			,[einspeisezaehlpunkt_gueltig_ab]
			,[id_abn]
			,[einspeiseanlage]
			,[energietraeger]
			,[id_status]
			,[status]
			,[storniert_am]
			,[id_einspeiseart]
			,[einspeiseart]
			,[einspeiseanlage_aenderungstyp]    
			,[installierte_leistung]       
			,[bnetza_eeg_schluessel]
			,[bnetzameldedatum]
			,[bnetza_aso_nr]
			,[marktstammdatenregister_nummer]
			,[marktstammdatenregister_registriert_am]
			,[id_nvp]
			,[netzverknuepfungspunkt]
			,[nvp_gueltig_ab]
			,[inbetriebnahme]
			,[stilllegungsdatum]
			,[netzzugang]
			,[netzabgang]
			,[aufnahme_dauerbetrieb]
			,[stromerzeugungseinheit_mastnr_nummer]
			,[stromerzeugungseinheit_mastnr_registriert_am]
			,[stromerzeugungseinheit_gueltig_ab]
			,[id_ressource]
			,[created_at]
			,[changed_at]
		)
		VALUES (
			 Source.[id_einspeiseanlage]
			,Source.[id_mandant]
			,Source.[id_zp]
			,Source.[id_zp_einspeisezaehlpunkt]
			,Source.[einspeisezaehlpunkt_gueltig_ab]
			,Source.[id_abn]
			,Source.[einspeiseanlage]
			,Source.[energietraeger]
			,Source.[id_status]
			,Source.[status]
			,Source.[storniert_am]
			,Source.[id_einspeiseart]
			,Source.[einspeiseart]
			,Source.[einspeiseanlage_aenderungstyp]
			,Source.[installierte_leistung]
			,Source.[bnetza_eeg_schluessel]
			,Source.[bnetzameldedatum]
			,Source.[bnetza_aso_nr]
			,Source.[marktstammdatenregister_nummer]
			,Source.[marktstammdatenregister_registriert_am]
			,Source.[id_nvp]
			,Source.[netzverknuepfungspunkt]
			,Source.[nvp_gueltig_ab]
			,Source.[inbetriebnahme]
			,Source.[stilllegungsdatum]
			,Source.[netzzugang]
			,Source.[netzabgang]
			,Source.[aufnahme_dauerbetrieb]
			,Source.[stromerzeugungseinheit_mastnr_nummer]
			,Source.[stromerzeugungseinheit_mastnr_registriert_am]
			,Source.[stromerzeugungseinheit_gueltig_ab]
			,Source.[id_ressource]
			,Source.[created_at]
			,Source.[changed_at]
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
