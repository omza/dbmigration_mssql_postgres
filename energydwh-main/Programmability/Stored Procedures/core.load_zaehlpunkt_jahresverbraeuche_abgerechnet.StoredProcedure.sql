-- Object: core.load_zaehlpunkt_jahresverbraeuche_abgerechnet
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		[core].[zaehlpunkt_jahresverbraeuche_abgerechnet]
	

-- Change Log

	19.10.2026	OME initial
	21.10.2026	OMe	letzen Satz je Messeinheit markieren
	


-- Test:

	exec core.[load_zaehlpunkt_jahresverbraeuche_abgerechnet] -1, 1 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_zaehlpunkt_jahresverbraeuche_abgerechnet]
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
		SELECT
			[id_link_messeinheit]
			,[id_zp]
			,[id_energieart]
			,[Jahresverbrauch_kwh_gesamt]
			,[Jahresverbrauch_kwh_nt]
			,[gueltig_von]
			,[gueltig_bis]
			,[abgerechnete_tage]
			,[messeinheit_letzte_zeitscheibe]
			,[created_at]
			,[changed_at]

			,checksum(
				[id_link_messeinheit]
				,[id_energieart]
				,[Jahresverbrauch_kwh_gesamt]
				,[Jahresverbrauch_kwh_nt]
				,[gueltig_bis]
				,[abgerechnete_tage]
				,[messeinheit_letzte_zeitscheibe]
				,[created_at]
				,[changed_at]
			) as [checksum]

		FROM
			[core].[zaehlpunkt_jahresverbraeuche_abgerechnet]


		----------------
	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		SELECT
			[id_link_messeinheit]
			,[id_zp]
			,[id_energieart]
			,[Jahresverbrauch_kwh_gesamt]
			,[Jahresverbrauch_kwh_nt]
			,[gueltig_von]
			,[gueltig_bis]
			,[abgerechnete_tage]
			,[messeinheit_letzte_zeitscheibe]
			,[created_at]
			,[changed_at]
			,checksum(
				[id_link_messeinheit]
				,[id_energieart]
				,[Jahresverbrauch_kwh_gesamt]
				,[Jahresverbrauch_kwh_nt]
				,[gueltig_bis]
				,[abgerechnete_tage]
				,[messeinheit_letzte_zeitscheibe]
				,[created_at]
				,[changed_at]
			) as [checksum]
		FROM
			[stage].[wilken_zaehlpunkt_jahresverbrauch]

		----- QUELLE -----
	)
	AS 
		Source	
	ON		
		Source.[id_zp] = Target.[id_zp]
		and Source.[gueltig_von] = Target.[gueltig_von]

	WHEN MATCHED AND Source.[checksum] != Target.[checksum] THEN 
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
					Target.changed_at	=	Source.changed_at
				,	Target.[created_at]	=	Source.[created_at]

				,	Target.[id_link_messeinheit]	=	Source.[id_link_messeinheit]
				,	Target.[id_energieart]	=	Source.[id_energieart]
				,	Target.[Jahresverbrauch_kwh_gesamt]	=	Source.[Jahresverbrauch_kwh_gesamt]
				,	Target.[Jahresverbrauch_kwh_nt]	=	Source.[Jahresverbrauch_kwh_nt]
				,	Target.[gueltig_bis]	=	Source.[gueltig_bis]
				,	Target.[abgerechnete_tage]	=	Source.[abgerechnete_tage]
				,	Target.[messeinheit_letzte_zeitscheibe]	=	Source.[messeinheit_letzte_zeitscheibe]


	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
			[id_link_messeinheit]
			,[id_zp]
			,[id_energieart]
			,[Jahresverbrauch_kwh_gesamt]
			,[Jahresverbrauch_kwh_nt]
			,[gueltig_von]
			,[gueltig_bis]
			,[abgerechnete_tage]
			,[created_at]
			,[changed_at]
			,[messeinheit_letzte_zeitscheibe]
		)
		VALUES (
			Source.[id_link_messeinheit]
			,Source.[id_zp]
			,Source.[id_energieart]
			,Source.[Jahresverbrauch_kwh_gesamt]
			,Source.[Jahresverbrauch_kwh_nt]
			,Source.[gueltig_von]
			,Source.[gueltig_bis]
			,Source.[abgerechnete_tage]
			,Source.[created_at]
			,Source.[changed_at]
			,Source.[messeinheit_letzte_zeitscheibe]
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
