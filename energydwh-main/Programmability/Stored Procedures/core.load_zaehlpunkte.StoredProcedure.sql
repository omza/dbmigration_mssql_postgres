-- Object: core.load_zaehlpunkte
-- Type  : SQL_STORED_PROCEDURE



/* =============================================
-- Author:		Oliver Meyer
-- Create date: 04.02.2025
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		core.zaehlpunkte
	

-- Change Log

	04.02.2025	OME initial
	30.06.2025	OME Abnahmestellenadresse Bestandteile auch aufgeblättert laden
	14.07.2025	OMe	Geolocation der Abnahmestellenadresse
	21.07.2025	OMe	Fallgruppen Verbrauch
						Falsch am 22.07. wieder entfernt ist nicht eindeutig für den ZP (analog Malo)

	26.02.2026	OMe	Füge Netzbetreiber Information hinzu 
	17.06.2026	OME	hinzufügen des abnahmestellenstatus ABN_STATUS
	18.06.2026	OMe hinzufügen von ENZPTDaten
	26.06.2026	OMe	hinzufügen von Bilanzierungsdaten (SLP und Zaehlverfahren)
	08.09.2026	OMe	Messstellenbetreiber



-- Test:

	exec core.[load_zaehlpunkte] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_zaehlpunkte]
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
		Pflege core.zaehlpunkt
	*/
	;WITH TargetRows AS 
	(
		----- ZIEL -----

		SELECT
			id_zp
			,[wilken_zpt_id]
			,[id_mandant]
			,[meteringcode]
			,[id_energieart]
			,[id_zp_typ]
			,[abnahmestelle_adresse]
			,[ablesetour_nr]
			,[wilken_brw_nr]
			,[wilken_zpt_ismesslokation]
			,[wilken_zpt_komplexemessung]
			,[created_at]
			,[changed_at]
			,abnahmestelle_straße
			,abnahmestelle_hausnummer
			,abnahmestelle_hausnummer_zusatz
			,abnahmestelle_plz
			,abnahmestelle_ort
			--14.07.2025 
			,abnahmestelle_lat
			,abnahmestelle_lon
			,abnahmestelle_location_type
			-- 26.02.2026
			,id_abn
			,id_netz
			-- 17.06.2026
			,abnahmestelle_status
			-- 18.06.2026
			,[id_spannungsebene]
			,[id_spannungsebene_messung]
			,[anschlussleistung]
			,[installierte_leistung]
			,[gasdruck_mbar]
			-- 26.06.2026
			,[id_lastprofil]
			,[id_zaehlverfahren]
			-- 08.09.2026
			,id_messstellenbetreiber
			,grundzustaendig_messstellenbetreiber

			,CHECKSUM(
				[wilken_zpt_id]
				,id_mandant
				,[meteringcode]
				,[id_energieart]
				,[id_zp_typ]
				,[abnahmestelle_adresse]
				,[ablesetour_nr]
				,[wilken_brw_nr]
				,[wilken_zpt_ismesslokation]
				,[wilken_zpt_komplexemessung]
				,[created_at]
				,[changed_at]
				,abnahmestelle_straße
				,abnahmestelle_hausnummer
				,abnahmestelle_hausnummer_zusatz
				,abnahmestelle_plz
				,abnahmestelle_ort
				,abnahmestelle_lat
				,abnahmestelle_lon
				,abnahmestelle_location_type
				,id_abn
				,id_netz
				,abnahmestelle_status
				,[id_spannungsebene]
				,[id_spannungsebene_messung]
				,[anschlussleistung]
				,[installierte_leistung]
				,[gasdruck_mbar]
				-- 26.06.2026
				,[id_lastprofil]
				,[id_zaehlverfahren]
				--08.09.26
				,id_messstellenbetreiber
				,grundzustaendig_messstellenbetreiber
			) as CHECKSUM
		
		FROM 
			[core].[zaehlpunkte]
		AS	Dim


	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		select  distinct
			[wilken_zpt_id] as id_zp
			,id_mandant
			,[wilken_zpt_id]
			,[meteringcode]
			,[id_energieart]
			,[id_zp_typ]
			,[abnahmestelle_adresse]
			,[ablesetour_nr]
			,[wilken_brw_nr]
			,[wilken_zpt_ismesslokation]
			,[wilken_zpt_komplexemessung]
			,zp.[created_at]
			,zp.[changed_at]
			,abnahmestelle_straße
			,abnahmestelle_hausnummer
			,abnahmestelle_hausnummer_zusatz
			,abnahmestelle_plz
			,abnahmestelle_ort
			--14.07.2025 
			,loc.abnahmestelle_lat
			,loc.abnahmestelle_lon
			,loc.abnahmestelle_location_type
			,id_abn
			,id_netz
			-- 17.06.2026
			,abnahmestelle_status
			--18.06.2026
			,[id_spannungsebene]
			,[id_spannungsebene_messung]
			,[anschlussleistung]
			,[installierte_leistung]
			,[gasdruck_mbar]
			-- 26.06.2026
			,[id_lastprofil]
			,[id_zaehlverfahren]
			--08.09.26
			,id_messstellenbetreiber
			,grundzustaendig_messstellenbetreiber

			,CHECKSUM(
				[wilken_zpt_id]
				,id_mandant
				,[meteringcode]
				,[id_energieart]
				,[id_zp_typ]
				,[abnahmestelle_adresse]
				,[ablesetour_nr]
				,[wilken_brw_nr]
				,[wilken_zpt_ismesslokation]
				,[wilken_zpt_komplexemessung]
				,zp.[created_at]
				,zp.[changed_at]
				,abnahmestelle_straße
				,abnahmestelle_hausnummer
				,abnahmestelle_hausnummer_zusatz
				,abnahmestelle_plz
				,abnahmestelle_ort
				,loc.abnahmestelle_lat
				,loc.abnahmestelle_lon
				,loc.abnahmestelle_location_type
				,id_abn
				,id_netz
				,abnahmestelle_status
				,[id_spannungsebene]
				,[id_spannungsebene_messung]
				,[anschlussleistung]
				,[installierte_leistung]
				,[gasdruck_mbar]
				-- 26.06.2026
				,[id_lastprofil]
				,[id_zaehlverfahren]
				--08.09.26
				,id_messstellenbetreiber
				,grundzustaendig_messstellenbetreiber
			) as CHECKSUM
		from
			[stage].[wilken_zaehlpunkt] zp
		join
			core.mandant mnd on zp.wilken_mnd_id = mnd.wilken_mnd_id
		left join
			stage.[wilken_zaehlpunkt_geolocation] loc on zp.[wilken_zpt_id] = loc.id_zp
		

		----- QUELLE -----
	)
	AS Source	ON	 Source.id_zp = Target.id_zp

	WHEN MATCHED AND Source.CHECKSUM != Target.CHECKSUM THEN

		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
				Target.changed_at	=	Source.changed_at

			,	Target.id_mandant	=	Source.id_mandant
			,	Target.wilken_zpt_id	=	Source.wilken_zpt_id
			,	Target.[meteringcode]	=	Source.[meteringcode]
			,	Target.[id_energieart]	=	Source.[id_energieart]
			,	Target.[id_zp_typ]	=	Source.[id_zp_typ]

			,	Target.[abnahmestelle_adresse]	=	Source.[abnahmestelle_adresse]
			,	Target.[ablesetour_nr]	=	Source.[ablesetour_nr]
			,	Target.[wilken_brw_nr]	=	Source.[wilken_brw_nr]

			,	Target.[wilken_zpt_ismesslokation]	=	Source.[wilken_zpt_ismesslokation]
			,	Target.[wilken_zpt_komplexemessung]	=	Source.[wilken_zpt_komplexemessung]

			,	Target.abnahmestelle_straße = Source.abnahmestelle_straße
			,	Target.abnahmestelle_hausnummer = Source.abnahmestelle_hausnummer
			,	Target.abnahmestelle_hausnummer_zusatz = Source.abnahmestelle_hausnummer_zusatz
			,	Target.abnahmestelle_plz = Source.abnahmestelle_plz
			,	Target.abnahmestelle_ort = Source.abnahmestelle_ort
			--14.07.2025
			,	Target.abnahmestelle_lat = Source.abnahmestelle_lat
			,	Target.abnahmestelle_lon = Source.abnahmestelle_lon
			,	Target.abnahmestelle_location_type = Source.abnahmestelle_location_type
			-- 26.02.2026
			,	Target.id_abn = Source.id_abn
			,	Target.id_netz = Source.id_netz
			-- 17.06.2026
			,	Target.abnahmestelle_status = Source.abnahmestelle_status
			--18.06.2026
			,	Target.[id_spannungsebene] = Source.[id_spannungsebene]
			,	Target.[id_spannungsebene_messung] = Source.[id_spannungsebene_messung]
			,	Target.[anschlussleistung] = Source.[anschlussleistung]
			,	Target.[installierte_leistung] = Source.[installierte_leistung]
			,	Target.[gasdruck_mbar] = Source.[gasdruck_mbar]
			-- 26.06.2026
			,	Target.[id_lastprofil] = Source.[id_lastprofil]	
			,	Target.[id_zaehlverfahren] = Source.[id_zaehlverfahren]

			--08.09.26
			,	Target.id_messstellenbetreiber = Source.id_messstellenbetreiber	
			,	Target.grundzustaendig_messstellenbetreiber = Source.grundzustaendig_messstellenbetreiber

	WHEN NOT MATCHED BY TARGET THEN

		----- INSERT, weil noch nicht vorhanden -----


		INSERT (
			id_zp
			,[wilken_zpt_id]
			,[id_mandant]
			,[meteringcode]
			,[id_energieart]
			,[id_zp_typ]
			,[abnahmestelle_adresse]
			,[ablesetour_nr]
			,[wilken_brw_nr]
			,[wilken_zpt_ismesslokation]
			,[wilken_zpt_komplexemessung]
			,[created_at]
			,[changed_at]

			,abnahmestelle_straße
			,abnahmestelle_hausnummer
			,abnahmestelle_hausnummer_zusatz
			,abnahmestelle_plz
			,abnahmestelle_ort
			
			,abnahmestelle_lat
			,abnahmestelle_lon
			,abnahmestelle_location_type

			,id_abn
			,id_netz
			,abnahmestelle_status

			,[id_spannungsebene]
			,[id_spannungsebene_messung]
			,[anschlussleistung]
			,[installierte_leistung]
			,[gasdruck_mbar]

			-- 26.06.2026
			,[id_lastprofil]
			,[id_zaehlverfahren]

			--08.09.26
			,id_messstellenbetreiber
			,grundzustaendig_messstellenbetreiber

		)
		VALUES (
			Source.id_zp
			,	Source.[wilken_zpt_id]
			,	Source.[id_mandant]
			,	Source.[meteringcode]
			,	Source.[id_energieart]
			,	Source.[id_zp_typ]
			,	Source.[abnahmestelle_adresse]
			,	Source.[ablesetour_nr]

			,	Source.[wilken_brw_nr]
			,	Source.[wilken_zpt_ismesslokation]
			,	Source.[wilken_zpt_komplexemessung]
			,	Source.[created_at]
			,	Source.[changed_at]

			,	Source.abnahmestelle_straße
			,	Source.abnahmestelle_hausnummer
			,	Source.abnahmestelle_hausnummer_zusatz
			,	Source.abnahmestelle_plz
			,	Source.abnahmestelle_ort

			,	Source.abnahmestelle_lat
			,	Source.abnahmestelle_lon
			,	Source.abnahmestelle_location_type

			,	Source.id_abn
			,	Source.id_netz

			,	Source.abnahmestelle_status

			,	Source.[id_spannungsebene]
			,	Source.[id_spannungsebene_messung]
			,	Source.[anschlussleistung]
			,	Source.[installierte_leistung]
			,	Source.[gasdruck_mbar]

			-- 26.06.2026
			,	Source.[id_lastprofil]
			,	Source.[id_zaehlverfahren]
			--08.09.26
			,	Source.id_messstellenbetreiber
			,	Source.grundzustaendig_messstellenbetreiber

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
