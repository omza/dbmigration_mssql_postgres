-- Object: core.load_zaehlpunkt_bilanzierungsdaten
-- Type  : SQL_STORED_PROCEDURE



/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		
		[core].[zaehlpunkt_bilanzierungsdaten]

-- Change Log

	16.11.2026	OMe	Übernehme nur Bilanzierungsdaten für ZP die in Core enthalten sind
	02.11.2026	OMe	Umstellung auf Checksum. Die Einschränkung auf last Change (Delta) funktioniert leider nicht, das Wilken Energy das Änderungsdatum an der Zeitscheibe nicht richtig aktualisiert
	20.10.2026	OME initial
	


-- Test:

	exec core.[load_zaehlpunkt_bilanzierungsdaten] -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_zaehlpunkt_bilanzierungsdaten]
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

	-- Hier wird nur das Delta ab dem letzten Änderungsdatum verglichen
	declare
		@lastchangedat as date = (
			select
				dateadd (DAY, -100, cast(max([changed_at]) as date))
			from
				[core].[zaehlpunkt_bilanzierungsdaten]
		)


	;WITH TargetRows AS 
	(
		----- ZIEL -----
		SELECT
			[id_zp]
			,[id_mandant]
			,[gueltig_ab]
			,[gueltig_bis]
			,[id_zaehlverfahren]
			,[id_lastprofil]
			,[jahresentnahme_kwh]
			,[id_bilanzierungsgebiet]
			,[messtechnik_malo]
			,[id_prognosegrundlage]
			,[created_at]
			,[changed_at]

			,checksum(
				[id_mandant]
				,[gueltig_bis]
				,[id_zaehlverfahren]
				,[id_lastprofil]
				,[jahresentnahme_kwh]
				,[id_bilanzierungsgebiet]
				,[messtechnik_malo]
				,[id_prognosegrundlage]
			) as [checksum]

		FROM
			[core].[zaehlpunkt_bilanzierungsdaten]


		----------------
	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		select
			bil.[id_zp]
			,bil.[id_mandant]
			,[gueltig_ab]
			,[gueltig_bis]
			,bil.[id_zaehlverfahren]
			,bil.[id_lastprofil]
			,[jahresentnahme_kwh]
			,[id_bilanzierungsgebiet]
			,[messtechnik_malo]
			,[id_prognosegrundlage]
			,bil.[created_at]
			,bil.[changed_at]
			,checksum(
				bil.[id_mandant]
				,[gueltig_bis]
				,bil.[id_zaehlverfahren]
				,bil.[id_lastprofil]
				,[jahresentnahme_kwh]
				,[id_bilanzierungsgebiet]
				,[messtechnik_malo]
				,[id_prognosegrundlage]
			) as [checksum]
		from 
			[stage].[wilken_zaehlpunkt_bilanzierung] bil
		join
			-- Übernehme nur Bilanzierungswerte für bekannte Zählpunkte
			-- damit referenzielle Integrität erhalten bleibt
			-- fehlende Zählpunkte müssen im Zeitabstand geprüft werden - warum die nicht in der parenttabelle drin sind
			core.zaehlpunkte zp on bil.id_zp = zp.id_zp

		----- QUELLE -----
	)
	AS 
		Source	
	ON		
		Source.[id_zp] = Target.[id_zp]
		and Source.[gueltig_ab] = Target.[gueltig_ab]

	WHEN MATCHED AND Source.[checksum] != Target.[checksum] THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					Target.changed_at	=	Source.changed_at
				,	Target.[created_at]	=	Source.[created_at]

				,	Target.[id_mandant]	=	Source.[id_mandant]
				,	Target.[id_zaehlverfahren]	=	Source.[id_zaehlverfahren]
				,	Target.[id_lastprofil]	=	Source.[id_lastprofil]
				,	Target.[jahresentnahme_kwh]	=	Source.[jahresentnahme_kwh]
				,	Target.[gueltig_bis]	=	Source.[gueltig_bis]
				,	Target.[id_bilanzierungsgebiet]	=	Source.[id_bilanzierungsgebiet]
				,	Target.[messtechnik_malo]	=	Source.[messtechnik_malo]
				,	Target.[id_prognosegrundlage]	=	Source.[id_prognosegrundlage]
				
	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_zp]
           ,[id_mandant]
           ,[gueltig_ab]
           ,[gueltig_bis]
           ,[id_zaehlverfahren]
           ,[id_lastprofil]
           ,[jahresentnahme_kwh]
           ,[id_bilanzierungsgebiet]
           ,[messtechnik_malo]
           ,[id_prognosegrundlage]
           ,[created_at]
           ,[changed_at]
		)
		VALUES (
			Source.[id_zp]
           ,Source.[id_mandant]
           ,Source.[gueltig_ab]
           ,Source.[gueltig_bis]
           ,Source.[id_zaehlverfahren]
           ,Source.[id_lastprofil]
           ,Source.[jahresentnahme_kwh]
           ,Source.[id_bilanzierungsgebiet]
           ,Source.[messtechnik_malo]
           ,Source.[id_prognosegrundlage]
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
