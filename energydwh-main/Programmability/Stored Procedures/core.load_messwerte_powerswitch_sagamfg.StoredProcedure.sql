-- Object: core.load_messwerte_powerswitch_sagamfg
-- Type  : SQL_STORED_PROCEDURE




/* =============================================
-- Author:		Oliver Meyer
-- Create date: 24.03.2025
-- Description:	
	
	lädt die wesswerte aus  powerswitch datenbank für die SAGA mfgs
		core.messwerte_lastgang_60min
	

-- Change Log

	24.03.2025	OME initial
	27.03.2025	OMe	selektiere zeitumstellung und typtag aus core.kalender
	


-- Test:

	exec core.[load_messwerte_powerswitch_sagamfg] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_messwerte_powerswitch_sagamfg]
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
		Pflege core.messpunkte
	*/
	;WITH TargetRows AS 
	(
		----- ZIEL -----

		SELECT 
			[id_messpunkt]
			,[id_energieart]
			,[id_obis]
			,[messeinheit]
			,[tag]
			,[id_typtag]
			,[id_zeitumstellung]
			,id_version
			,[max_wert]
			,[summe_wert]
			,[tagesverbrauch_kWh]
			,[0]
			,[1]
			,[2]
			,[3]
			,[4]
			,[5]
			,[6]
			,[7]
			,[8]
			,[9]
			,[10]
			,[11]
			,[12]
			,[13]
			,[14]
			,[15]
			,[16]
			,[17]
			,[18]
			,[19]
			,[20]
			,[21]
			,[22]
			,[23]
			,[b_stunde]
			--
			,[wertstatus_gesamt]
			,[wertstatus_0]
			,[wertstatus_1]
			,[wertstatus_2]
			,[wertstatus_3]
			,[wertstatus_4]
			,[wertstatus_5]
			,[wertstatus_6]
			,[wertstatus_7]
			,[wertstatus_8]
			,[wertstatus_9]
			,[wertstatus_10]
			,[wertstatus_11]
			,[wertstatus_12]
			,[wertstatus_13]
			,[wertstatus_14]
			,[wertstatus_15]
			,[wertstatus_16]
			,[wertstatus_17]
			,[wertstatus_18]
			,[wertstatus_19]
			,[wertstatus_20]
			,[wertstatus_21]
			,[wertstatus_22]
			,[wertstatus_23]
			,[wertstatus_b_stunde]
			--
			,[created_at]
			,[changed_at]
			,checksum(
				[id_energieart]
				,[messeinheit]
				,[id_typtag]
				,[id_zeitumstellung]
				,ISNULL([max_wert],0)
				,ISNULL([summe_wert],0)
				,ISNULL([tagesverbrauch_kWh],0)
				,ISNULL([0],0)
				,ISNULL([1],0)
				,ISNULL([2],0)
				,ISNULL([3],0)
				,ISNULL([4],0)
				,ISNULL([5],0)
				,ISNULL([6],0)
				,ISNULL([7],0)
				,ISNULL([8],0)
				,ISNULL([9],0)
				,ISNULL([10],0)
				,ISNULL([11],0)
				,ISNULL([12],0)
				,ISNULL([13],0)
				,ISNULL([14],0)
				,ISNULL([15],0)
				,ISNULL([16],0)
				,ISNULL([17],0)
				,ISNULL([18],0)
				,ISNULL([19],0)
				,ISNULL([20],0)
				,ISNULL([21],0)
				,ISNULL([22],0)
				,ISNULL([23],0)
				,ISNULL([b_stunde],0)

			) as checksum
		FROM 
			[core].[messwerte_lastgang_60min]
		
		AS	Dim



	)

	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		SELECT 
			id_messpunkt, 
			id_energieart, 
			id_obis, 
			messeinheit, 
			tag,
			id_typtag,
			id_zeitumstellung,
			1 id_version,
			(select max(i) from (values ([0]),([1]),([2]),([3]),([4]),([5]),([6]),([7]),([8]),([9]),([10]),([11]),([12]),([13]),([14]),([15]),([16]),([17]),([18]),([19]),([20]),([21]),([22]),([23])) AS T(i)) as max_wert,
			CASE 
				when id_zeitumstellung = 0 THEN	CAST(([0]+[1]+[2]+[3]+[4]+[5]+[6]+[7]+[8]+[9]+[10]+[11]+[12]+[13]+[14]+[15]+[16]+[17]+[18]+[19]+[20]+[21]+[22]+[23]) as DECIMAL(15,3)) 
				when id_zeitumstellung = 1 THEN CAST(([0]+[1]+[3]+[4]+[5]+[6]+[7]+[8]+[9]+[10]+[11]+[12]+[13]+[14]+[15]+[16]+[17]+[18]+[19]+[20]+[21]+[22]+[23]) as DECIMAL(15,3))
				when id_zeitumstellung = 2 THEN	CAST(([0]+[1]+[2]+[3]+[4]+[5]+[6]+[7]+[8]+[9]+[10]+[11]+[12]+[13]+[14]+[15]+[16]+[17]+[18]+[19]+[20]+[21]+[22]+[23]+ 0/*b_stunde*/) as DECIMAL(15,3)) 
			END
			as summe_wert,
			CASE 
				when id_zeitumstellung = 0 THEN	CAST(([0]+[1]+[2]+[3]+[4]+[5]+[6]+[7]+[8]+[9]+[10]+[11]+[12]+[13]+[14]+[15]+[16]+[17]+[18]+[19]+[20]+[21]+[22]+[23])/1000 as DECIMAL(15,3)) 
				when id_zeitumstellung = 1 THEN CAST(([0]+[1]+[3]+[4]+[5]+[6]+[7]+[8]+[9]+[10]+[11]+[12]+[13]+[14]+[15]+[16]+[17]+[18]+[19]+[20]+[21]+[22]+[23])/1000 as DECIMAL(15,3))
				when id_zeitumstellung = 2 THEN	CAST(([0]+[1]+[2]+[3]+[4]+[5]+[6]+[7]+[8]+[9]+[10]+[11]+[12]+[13]+[14]+[15]+[16]+[17]+[18]+[19]+[20]+[21]+[22]+[23]+ 0/*b_stunde*/)/1000 as DECIMAL(15,3)) 
			END
			as tagesverbrauch_kWh,
			[0],[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23], null [b_stunde]
			,0 [wertstatus_gesamt]
			,CASE WHEN [0] IS NULL THEN NULL ELSE 0 END as [wertstatus_0]
			,CASE WHEN [1] IS NULL THEN NULL ELSE 0 END as [wertstatus_1]
			,CASE WHEN [2] IS NULL THEN NULL ELSE 0 END as [wertstatus_2]
			,CASE WHEN [3] IS NULL THEN NULL ELSE 0 END as [wertstatus_3]
			,CASE WHEN [4] IS NULL THEN NULL ELSE 0 END as [wertstatus_4]
			,CASE WHEN [5] IS NULL THEN NULL ELSE 0 END as [wertstatus_5]
			,CASE WHEN [6] IS NULL THEN NULL ELSE 0 END as [wertstatus_6]
			,CASE WHEN [7] IS NULL THEN NULL ELSE 0 END as [wertstatus_7]
			,CASE WHEN [8] IS NULL THEN NULL ELSE 0 END as [wertstatus_8]
			,CASE WHEN [9] IS NULL THEN NULL ELSE 0 END as [wertstatus_9]
			,CASE WHEN [10] IS NULL THEN NULL ELSE 0 END as [wertstatus_10]
			,CASE WHEN [11] IS NULL THEN NULL ELSE 0 END as [wertstatus_11]
			,CASE WHEN [12] IS NULL THEN NULL ELSE 0 END as [wertstatus_12]
			,CASE WHEN [13] IS NULL THEN NULL ELSE 0 END as [wertstatus_13]
			,CASE WHEN [14] IS NULL THEN NULL ELSE 0 END as [wertstatus_14]
			,CASE WHEN [15] IS NULL THEN NULL ELSE 0 END as [wertstatus_15]
			,CASE WHEN [16] IS NULL THEN NULL ELSE 0 END as [wertstatus_16]
			,CASE WHEN [17] IS NULL THEN NULL ELSE 0 END as [wertstatus_17]
			,CASE WHEN [18] IS NULL THEN NULL ELSE 0 END as [wertstatus_18]
			,CASE WHEN [19] IS NULL THEN NULL ELSE 0 END as [wertstatus_19]
			,CASE WHEN [20] IS NULL THEN NULL ELSE 0 END as [wertstatus_20]
			,CASE WHEN [21] IS NULL THEN NULL ELSE 0 END as [wertstatus_21]
			,CASE WHEN [22] IS NULL THEN NULL ELSE 0 END as [wertstatus_22]
			,CASE WHEN [23] IS NULL THEN NULL ELSE 0 END as [wertstatus_23]
			,NULL [wertstatus_b_stunde]

			,checksum(
				[id_energieart]
				,[messeinheit]
				,id_typtag
				,id_zeitumstellung
				,ISNULL((select max(i) from (values ([0]),([1]),([2]),([3]),([4]),([5]),([6]),([7]),([8]),([9]),([10]),([11]),([12]),([13]),([14]),([15]),([16]),([17]),([18]),([19]),([20]),([21]),([22]),([23])) AS T(i)),0)
				,ISNULL(CAST(([0]+[1]+[2]+[3]+[4]+[5]+[6]+[7]+[8]+[9]+[10]+[11]+[12]+[13]+[14]+[15]+[16]+[17]+[18]+[19]+[20]+[21]+[22]+[23]) as DECIMAL(15,3)),0)
				,ISNULL(CAST(([0]+[1]+[2]+[3]+[4]+[5]+[6]+[7]+[8]+[9]+[10]+[11]+[12]+[13]+[14]+[15]+[16]+[17]+[18]+[19]+[20]+[21]+[22]+[23])/1000 as DECIMAL(15,3)),0)
				,ISNULL([0],0)
				,ISNULL([1],0)
				,ISNULL([2],0)
				,ISNULL([3],0)
				,ISNULL([4],0)
				,ISNULL([5],0)
				,ISNULL([6],0)
				,ISNULL([7],0)
				,ISNULL([8],0)
				,ISNULL([9],0)
				,ISNULL([10],0)
				,ISNULL([11],0)
				,ISNULL([12],0)
				,ISNULL([13],0)
				,ISNULL([14],0)
				,ISNULL([15],0)
				,ISNULL([16],0)
				,ISNULL([17],0)
				,ISNULL([18],0)
				,ISNULL([19],0)
				,ISNULL([20],0)
				,ISNULL([21],0)
				,ISNULL([22],0)
				,ISNULL([23],0)
				,0 -- bstunde
			) as checksum
		FROM
		(
		SELECT 
			id_messpunkt
			,1 id_energieart
			,11160 as id_obis
			,'Watt ' as messeinheit
			,convert(date, date_2, 120) as tag
			,id_typtag
			,id_zeitumstellung
			,DATEPART(HOUR,convert(datetime, date_2, 120)) as stunde
			,CAST([leistung] as DECIMAL(15,3)) Watt
		FROM 
			[raw].[power_switch_power_eltek_saga] pwr
		join
			core.messpunkte dev on pwr.device = dev.messpunkt_ident and dev.id_quellsystem = 3 
		join
			(select distinct tag, id_typtag, id_zeitumstellung from core.kalender) cal on convert(date, date_2, 120) = cal.tag
		) AS Quelle
		PIVOT
		(
		max(Watt)
		FOR stunde IN ([0],[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23])
		) AS PivotTabelle

		----- QUELLE -----
	)
	AS Source	
	ON	 
		Source.id_messpunkt = Target.id_messpunkt 
		and Source.id_obis = Target.id_obis
		and Source.tag = Target.tag

	WHEN MATCHED AND Source.CHECKSUM != Target.CHECKSUM THEN

		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
				Target.changed_at	=	GETDATE()
			,	Target.[id_energieart]	=	Source.[id_energieart]
			,	Target.messeinheit	=	Source.messeinheit

			,	Target.id_typtag	=	Source.id_typtag
			,	Target.id_zeitumstellung	=	Source.id_zeitumstellung
			,	Target.id_version = Target.id_version + 1 
			,	Target.max_wert	=	Source.max_wert

			,	Target.summe_wert	=	Source.summe_wert
			,	Target.tagesverbrauch_kWh	=	Source.tagesverbrauch_kWh

			, Target.[0] = Source.[0]
			, Target.[1] = Source.[1]
			, Target.[2] = Source.[2]
			, Target.[3] = Source.[3]
			, Target.[4] = Source.[4]
			, Target.[5] = Source.[5]
			, Target.[6] = Source.[6]
			, Target.[7] = Source.[7]
			, Target.[8] = Source.[8]
			, Target.[9] = Source.[9]
			, Target.[10] = Source.[10]
			, Target.[11] = Source.[11]
			, Target.[12] = Source.[12]
			, Target.[13] = Source.[13]
			, Target.[14] = Source.[14]
			, Target.[15] = Source.[15]
			, Target.[16] = Source.[16]
			, Target.[17] = Source.[17]
			, Target.[18] = Source.[18]
			, Target.[19] = Source.[19]
			, Target.[20] = Source.[20]
			, Target.[21] = Source.[21]
			, Target.[22] = Source.[22]
			, Target.[23] = Source.[23]

			, Target.[wertstatus_gesamt] = CASE WHEN Source.tagesverbrauch_kWh is null THEN NULL ELSE 0 END

			, Target.[wertstatus_0] = Source.[wertstatus_0]
			, Target.[wertstatus_1] = Source.[wertstatus_1]
			, Target.[wertstatus_2] = Source.[wertstatus_2]
			, Target.[wertstatus_3] = Source.[wertstatus_3]
			, Target.[wertstatus_4] = Source.[wertstatus_4]
			, Target.[wertstatus_5] = Source.[wertstatus_5]
			, Target.[wertstatus_6] = Source.[wertstatus_6]
			, Target.[wertstatus_7] = Source.[wertstatus_7]
			, Target.[wertstatus_8] = Source.[wertstatus_8]
			, Target.[wertstatus_9] = Source.[wertstatus_9]
			, Target.[wertstatus_10] = Source.[wertstatus_10]
			, Target.[wertstatus_11] = Source.[wertstatus_11]
			, Target.[wertstatus_12] = Source.[wertstatus_12]
			, Target.[wertstatus_13] = Source.[wertstatus_13]
			, Target.[wertstatus_14] = Source.[wertstatus_14]
			, Target.[wertstatus_15] = Source.[wertstatus_15]
			, Target.[wertstatus_16] = Source.[wertstatus_16]
			, Target.[wertstatus_17] = Source.[wertstatus_17]
			, Target.[wertstatus_18] = Source.[wertstatus_18]
			, Target.[wertstatus_19] = Source.[wertstatus_19]
			, Target.[wertstatus_20] = Source.[wertstatus_20]
			, Target.[wertstatus_21] = Source.[wertstatus_21]
			, Target.[wertstatus_22] = Source.[wertstatus_22]
			, Target.[wertstatus_23] = Source.[wertstatus_23]




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
			,id_version
			,[max_wert]
			,[summe_wert]
			,[tagesverbrauch_kWh]
			,[0]
			,[1]
			,[2]
			,[3]
			,[4]
			,[5]
			,[6]
			,[7]
			,[8]
			,[9]
			,[10]
			,[11]
			,[12]
			,[13]
			,[14]
			,[15]
			,[16]
			,[17]
			,[18]
			,[19]
			,[20]
			,[21]
			,[22]
			,[23]
			,[b_stunde]
			--
			,[wertstatus_gesamt]
			,[wertstatus_0]
			,[wertstatus_1]
			,[wertstatus_2]
			,[wertstatus_3]
			,[wertstatus_4]
			,[wertstatus_5]
			,[wertstatus_6]
			,[wertstatus_7]
			,[wertstatus_8]
			,[wertstatus_9]
			,[wertstatus_10]
			,[wertstatus_11]
			,[wertstatus_12]
			,[wertstatus_13]
			,[wertstatus_14]
			,[wertstatus_15]
			,[wertstatus_16]
			,[wertstatus_17]
			,[wertstatus_18]
			,[wertstatus_19]
			,[wertstatus_20]
			,[wertstatus_21]
			,[wertstatus_22]
			,[wertstatus_23]
			,[wertstatus_b_stunde]
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
			, Source.[max_wert]
			, Source.[summe_wert]
			, Source.[tagesverbrauch_kWh]
			, Source.[0]
			, Source.[1]
			, Source.[2]
			, Source.[3]
			, Source.[4]
			, Source.[5]
			, Source.[6]
			, Source.[7]
			, Source.[8]
			, Source.[9]
			, Source.[10]
			, Source.[11]
			, Source.[12]
			, Source.[13]
			, Source.[14]
			, Source.[15]
			, Source.[16]
			, Source.[17]
			, Source.[18]
			, Source.[19]
			, Source.[20]
			, Source.[21]
			, Source.[22]
			, Source.[23]
			, Source.[b_stunde]

			, CASE WHEN Source.tagesverbrauch_kWh is null THEN NULL ELSE 0 END
			, Source.[wertstatus_0]
			, Source.[wertstatus_1]
			, Source.[wertstatus_2]
			, Source.[wertstatus_3]
			, Source.[wertstatus_4]
			, Source.[wertstatus_5]
			, Source.[wertstatus_6]
			, Source.[wertstatus_7]
			, Source.[wertstatus_8]
			, Source.[wertstatus_9]
			, Source.[wertstatus_10]
			, Source.[wertstatus_11]
			, Source.[wertstatus_12]
			, Source.[wertstatus_13]
			, Source.[wertstatus_14]
			, Source.[wertstatus_15]
			, Source.[wertstatus_16]
			, Source.[wertstatus_17]
			, Source.[wertstatus_18]
			, Source.[wertstatus_19]
			, Source.[wertstatus_20]
			, Source.[wertstatus_21]
			, Source.[wertstatus_22]
			, Source.[wertstatus_23]
			, Source.[wertstatus_b_stunde]
		)

	;
	
	/*
		bereinigen der raw tabelle

		lösche alle Messwerte bis auf die maximalen sätze. das lasse ich nochmal auskommentiert, nach der Zeitumstellung muss ich hier nochmal ran

	with max_werte as (
		select
			device,
			max(convert(date, date_2, 120)) as max_tag
		from
			raw.power_switch_power_eltek_saga
		group by
			device
	)

	delete from powerswitch
	from
		raw.power_switch_power_eltek_saga powerswitch
	join
		max_werte mw on powerswitch.device = mw.device
	where
		convert(date, powerswitch.date_2, 120) < mw.max_tag	
	
	*/		




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
