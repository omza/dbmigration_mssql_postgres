-- Object: core.load_messwerte_powerswitch_sagaipuep
-- Type  : SQL_STORED_PROCEDURE




/* =============================================
-- Author:		Oliver Meyer
-- Create date: 26.03.2025
-- Description:	
	
	lädt die wesswerte aus  powerswitch datenbank für die SAGA ipueps
		core.messwerte_tag
	

-- Change Log

	26.03.2025	OME initial
	27.03.2025	OMe	selektiere zeitumstellung und typtag aus core.kalender
					Wertstatus ist hier immer 1 = Ersatzwert da es sich um eine rechnerisch ermittelte größe handelt
	
	01.07.2025	OMe Source Select = Distinct	

	04.11.2026	OMe	Umstellung auf berechnete Werte aus nedi = Analog berechnet zu powerswitch

-- Test:

	exec core.[load_messwerte_powerswitch_sagaipuep] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_messwerte_powerswitch_sagaipuep]
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

	DECLARE @gestern as date = DATEADD(DAY,-1,CAST(GETDATE() as date))


	/*
		Pflege core.messpunkte
	*/
	;WITH ipuep_power as (
	
		select 

			nedi.*
			,power_card + power_chassis + power_mgmt as leistung     
		from 
			[stage].[nedi_ipueps_saga_power] nedi		

	),

	TargetRows AS 
	(
		----- ZIEL -----

		SELECT [id_messpunkt]
			  ,[id_energieart]
			  ,[id_obis]
			  ,[messeinheit]
			  ,[tag]
			  ,[id_typtag]
			  ,[id_zeitumstellung]
			  ,[id_version]
			  ,[tagesverbrauch_kWh]
			  ,[Wert]
			  ,[id_wertstatus]
			  ,[created_at]
			  ,[changed_at]
			  ,checksum(
					[id_energieart]
					,[messeinheit]
					,[id_typtag]
					,[id_zeitumstellung]
					,[tagesverbrauch_kWh]
					,[Wert]
					,[id_wertstatus]
			  ) as [CHECKSUM]
		  FROM 
			[core].[messwerte_tag]
			
				AS	Dim



	)

	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		SELECT distinct
			id_messpunkt, 
			1 id_energieart, 
			11160 id_obis, 
			'Watt' messeinheit, 
			cal.tag as tag,
			id_typtag,
			id_zeitumstellung,
			1 id_version,
			CAST((CAST([leistung] as DECIMAL(15,3)) * 24/1000) as DECIMAL(15,3))  as tagesverbrauch_kWh,
			CAST([leistung] as DECIMAL(15,3)) Wert,
			1 [id_wertstatus] -- Ersatzwert weil nur rechnerisch anhand der Kundenaufschaltungen ermittelter Wert
			,checksum(
				1
				,'Watt'
				,id_typtag
				,id_zeitumstellung
				,CAST((CAST([leistung] as DECIMAL(15,3)) * 24/1000) as DECIMAL(15,3)) 
				,CAST([leistung] as DECIMAL(15,3))
				,0
			) as [CHECKSUM]
		FROM
			ipuep_power pwr
		JOIN
			core.messpunkte dev on pwr.messpunkt_ident = dev.messpunkt_ident and dev.id_quellsystem = 3
		join
			(select distinct tag, id_typtag, id_zeitumstellung from core.kalender) cal on cal.tag between DATEADD(DAY,-2, @gestern) and @gestern
	

		----- QUELLE -----
	)
	AS Source	
	ON	 
		Source.id_messpunkt = Target.id_messpunkt 
		and Source.id_obis = Target.id_obis
		and Source.tag = Target.tag


	WHEN NOT MATCHED BY TARGET THEN

		----- INSERT, weil noch nicht vorhanden -----


		INSERT (
			[id_messpunkt]
			,[id_energieart]
			,[id_obis]
			,[messeinheit]
			,[tag]
			,[id_typtag]
			,[id_zeitumstellung]
			,[id_version]
			,[tagesverbrauch_kWh]
			,[Wert]
			,[id_wertstatus]
		)
		VALUES (
			 Source.[id_messpunkt]
			, Source.[id_energieart]
			, Source.[id_obis]
			, Source.[messeinheit]
			, Source.[tag]
			, Source.[id_typtag]
			, Source.[id_zeitumstellung]
			, Source.id_version
			, Source.[tagesverbrauch_kWh]
			, Source.[Wert]
			, Source.[id_wertstatus]
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
