-- Object: core.load_lokationsbuendel
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		
		core.lokationsbuendel
	

-- Change Log

	09.07.2026	OME initial
	10.07.2026	OMe	Strukturobject infos hinzu
	13.07.2026	OMe	Doppelte Merge Sätze - fix weil nicht beide PK Felder als Match Keys drin waren
	


-- Test:

	exec core.[load_lokationsbuendel] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_lokationsbuendel]
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
		Lokationsbündel Struktur aktualsierung
	*/

	MERGE INTO [core].[lokationsbuendelstruktur]	AS	Target
	USING
	(
		----- QUELLE -----
		select 
			[id_lokationsbuendelstruktur]
			,[lokationsbuendelstruktur_code]
			,[lokationsbuendelstruktur_bezeichnung]
			,[gueltig_ab]
			,[gueltig_bis]
			,[created_at]
			,[changed_at]
		from 
			[stage].[wilken_lokationsbuendelstruktur]
		----- QUELLE -----
	)
	AS Source	ON		Source.[id_lokationsbuendelstruktur] = Target.[id_lokationsbuendelstruktur]

	WHEN MATCHED  THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 

				Target.[lokationsbuendelstruktur_code]	= Source.[lokationsbuendelstruktur_code]
				,Target.[lokationsbuendelstruktur_bezeichnung] = Source.[lokationsbuendelstruktur_bezeichnung]
				,Target.[gueltig_ab] = Source.[gueltig_ab]
				,Target.[gueltig_bis] = Source.[gueltig_bis]
				,Target.[created_at] = Source.[created_at]
				,Target.[changed_at] = Source.[changed_at]

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_lokationsbuendelstruktur]
			,[lokationsbuendelstruktur_code]
			,[lokationsbuendelstruktur_bezeichnung]
			,[gueltig_ab]
			,[gueltig_bis]
			,[created_at]
			,[changed_at]
		)
		VALUES (
			Source.[id_lokationsbuendelstruktur]
			,Source.[lokationsbuendelstruktur_code]
			,Source.[lokationsbuendelstruktur_bezeichnung]
			,Source.[gueltig_ab]
			,Source.[gueltig_bis]
			,Source.[created_at]
			,Source.[changed_at]
		)

	;


	/*
		Pflege Lokationsbündelzeitscheiben
	*/
	;WITH TargetRows AS 
	(
		----- ZIEL -----
		select
			[id_lokationsbuendel_element]
			,[id_lokationsbuendel_zeitscheibe]
			,[id_lokationsbuendel]
			,[lokationsbuendel]
			,[lokationsbuendel_info]
			,[id_lokationsbuendelstruktur]
			,[id_mandant]
			,[id_abn]
			,[id_netzlokation]
			,[netzlokation]
			,[id_zp]
			,[id_malo_bezug]
			,[id_malo_einspeisung]
			,[id_ressource]
			,[id_melofunktion]
			,[melofunktion]
			,[id_ebene]
			,[id_richtung]
			,[richtung]
			,[gueltig_ab]
			,[gueltig_bis]
			,[id_lokationsbuendel_status]
			,[lokationsbuendel_status]
			,[created_at]
			,[changed_at]

			, checksum (
				[id_lokationsbuendel_zeitscheibe]
				,[id_lokationsbuendel]
				,[lokationsbuendel]
				,[lokationsbuendel_info]
				,[id_lokationsbuendelstruktur]
				,[id_abn]
				,[id_netzlokation]
				,[netzlokation]
				,[id_zp]
				,[id_malo_bezug]
				,[id_malo_einspeisung]
				,[id_melofunktion]
				,[melofunktion]
				,[id_ebene]
				,[id_richtung]
				,[richtung]
				,[gueltig_ab]
				,[gueltig_bis]
				,[id_lokationsbuendel_status]
				,[lokationsbuendel_status]
				,[created_at]
				,[changed_at]

			) as [CHECKSUMME]
	  from
		[EnergyDWH].[core].[lokationsbuendel]
		AS	Dim


	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		SELECT 
			[id_lokationsbuendel_element]
			,[id_lokationsbuendel_zeitscheibe]
			,[id_lokationsbuendel]
			,[lokationsbuendel]
			,[lokationsbuendel_info]
			,[id_lokationsbuendelstruktur]
			,[id_abn]
			,[id_netzlokation]
			,[netzlokation]
			,[id_zp]
			,[id_malo_bezug]
			,[id_malo_einspeisung]
			,[id_ressource]
			,[id_melofunktion]
			,[melofunktion]
			,[id_ebene]
			,[id_richtung]
			,[richtung]
			,[gueltig_ab]
			,[gueltig_bis]
			,[id_lokationsbuendel_status]
			,[lokationsbuendel_status]
			,[created_at]
			,[changed_at]
			, checksum (
				[id_lokationsbuendel_zeitscheibe]
				,[id_lokationsbuendel]
				,[lokationsbuendel]
				,[lokationsbuendel_info]
				,[id_lokationsbuendelstruktur]
				,[id_abn]
				,[id_netzlokation]
				,[netzlokation]
				,[id_zp]
				,[id_malo_bezug]
				,[id_malo_einspeisung]
				,[id_melofunktion]
				,[melofunktion]
				,[id_ebene]
				,[id_richtung]
				,[richtung]
				,[gueltig_ab]
				,[gueltig_bis]
				,[id_lokationsbuendel_status]
				,[lokationsbuendel_status]
				,[created_at]
				,[changed_at]

			) as [CHECKSUMME]
		FROM
			[stage].[wilken_lokationsbuendel]




		----- QUELLE -----
	)
	AS Source	ON		
		Source.[id_lokationsbuendel_element] = Target.[id_lokationsbuendel_element]
		and Source.id_ressource = Target.id_ressource

	WHEN MATCHED AND Source.[CHECKSUMME] != Target.[CHECKSUMME] THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 

			Target.[id_lokationsbuendel_zeitscheibe]   =       Source.[id_lokationsbuendel_zeitscheibe]
			,Target.[id_lokationsbuendel]               =       Source.[id_lokationsbuendel]
			,Target.[lokationsbuendel]                  =       Source.[lokationsbuendel]
			,Target.[lokationsbuendel_info]             =       Source.[lokationsbuendel_info]
			,Target.[id_lokationsbuendelstruktur]       =       Source.[id_lokationsbuendelstruktur]
			,Target.[id_abn]                            =       Source.[id_abn]
			,Target.[id_netzlokation]                   =       Source.[id_netzlokation]
			,Target.[netzlokation]                      =       Source.[netzlokation]
			,Target.[id_zp]                             =       Source.[id_zp]
			,Target.[id_malo_bezug]                     =       Source.[id_malo_bezug]
			,Target.[id_malo_einspeisung]               =       Source.[id_malo_einspeisung]
			,Target.[id_melofunktion]                   =       Source.[id_melofunktion]
			,Target.[melofunktion]                      =       Source.[melofunktion]
			,Target.[id_ebene]                          =       Source.[id_ebene]
			,Target.[id_richtung]                       =       Source.[id_richtung]
			,Target.[richtung]                          =       Source.[richtung]
			,Target.[gueltig_ab]                        =       Source.[gueltig_ab]
			,Target.[gueltig_bis]                       =       Source.[gueltig_bis]
			,Target.[id_lokationsbuendel_status]        =       Source.[id_lokationsbuendel_status]
			,Target.[lokationsbuendel_status]           =       Source.[lokationsbuendel_status]
			,Target.[created_at]                        =       Source.[created_at]
			,Target.[changed_at]                        =       Source.[changed_at]


	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_lokationsbuendel_element]
			,[id_lokationsbuendel_zeitscheibe]
			,[id_lokationsbuendel]
			,[lokationsbuendel]
			,[lokationsbuendel_info]
			,[id_lokationsbuendelstruktur]
			,[id_abn]
			,[id_netzlokation]
			,[netzlokation]
			,[id_zp]
			,[id_malo_bezug]
			,[id_malo_einspeisung]
			,[id_ressource]
			,[id_melofunktion]
			,[melofunktion]
			,[id_ebene]
			,[id_richtung]
			,[richtung]
			,[gueltig_ab]
			,[gueltig_bis]
			,[id_lokationsbuendel_status]
			,[lokationsbuendel_status]
			,[created_at]
			,[changed_at]
		)
		VALUES (
			 Source.[id_lokationsbuendel_element]
			,Source.[id_lokationsbuendel_zeitscheibe]
			,Source.[id_lokationsbuendel]
			,Source.[lokationsbuendel]
			,Source.[lokationsbuendel_info]
			,Source.[id_lokationsbuendelstruktur]
			,Source.[id_abn]
			,Source.[id_netzlokation]
			,Source.[netzlokation]
			,Source.[id_zp]
			,Source.[id_malo_bezug]
			,Source.[id_malo_einspeisung]
			,Source.[id_ressource]
			,Source.[id_melofunktion]
			,Source.[melofunktion]
			,Source.[id_ebene]
			,Source.[id_richtung]
			,Source.[richtung]
			,Source.[gueltig_ab]
			,Source.[gueltig_bis]
			,Source.[id_lokationsbuendel_status]
			,Source.[lokationsbuendel_status]
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
