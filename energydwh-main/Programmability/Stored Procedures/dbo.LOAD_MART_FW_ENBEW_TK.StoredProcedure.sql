-- Object: dbo.LOAD_MART_FW_ENBEW_TK
-- Type  : SQL_STORED_PROCEDURE
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[LOAD_MART_FW_ENBEW_TK]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Get SP Name
	DECLARE @SP_NAME varchar(100);
	SELECT @SP_NAME = OBJECT_NAME(@@PROCID);


	--	---------------------------------------------------
	BEGIN TRY
	--	---------------------------------------------------


	/*
		Dataset FWUE in mart_fw anlegen

	*/

	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[mart_fw].[enbew_tk]') AND type in (N'U'))
		DROP TABLE [mart_fw].enbew_tk


	CREATE TABLE [mart_fw].enbew_tk(
		[ZPT_ID] [decimal](12, 0) NOT NULL,
		[ZPT_METERINGCODE] [varchar](33) NOT NULL,
		[ABNAHMESTELLE]  [varchar](250) NULL,
		[KND_NR1] [varchar](20) NULL,
		[KAT_NR] [char](3)  NULL,
		[KAT_BEZEICHNUNG] [varchar](40) NULL,
		[PONAME] [varchar](250) NULL,
		[STRASSE] [varchar](84) NULL,
		[ORT] [varchar](51) NULL,
		[2020] [int] NULL,
		[2021] [int] NULL,
		[2022] [int] NULL,
		[2023] [int] NULL,
		[2024] [int] NULL,
		[KNG_BEZEICHNUNG] [varchar](50) NULL,
		[KND_LETZTERECHNUNG] [date] NULL,
		[KND_EINZUGDATUM] [date]  NULL,
		[KND_AUSZUGDATUM] [date] NULL,
		[ABN_LTO_NR] [decimal](5, 0) NULL
	) ON [PRIMARY]


	-- Letzter Kunde je ZPT
	IF OBJECT_ID('tempdb..#ZPT_ZU_KND', 'U') IS NOT NULL DROP TABLE #ZPT_ZU_KND

	CREATE TABLE #ZPT_ZU_KND
	(
		[ZPT_ID] [decimal](12, 0) NOT NULL,
		[KND_ID] [decimal](12, 0) NOT NULL
	)

	INSERT INTO #ZPT_ZU_KND 
	(		
		ZPT_ID,
		KND_ID
	)
	SELECT
		ZPT_ID,
		KND_ID
	FROM
		(	SELECT
				ZPT_ID,
				KND_ID,
				ROW_NUMBER() OVER (PARTITION BY ZPT_ID ORDER BY KNV_ENDE DESC) AS LFD_NR
			FROM
				[EnergyDWH].[insert].ENKNDVERBRAUCH
			WHERE
				ZPT_ID IS NOT NULL
				AND KNV_ENERGIEART <> 5
		) KND
	WHERE
		LFD_NR = 1




	-- Einfügen
	INSERT INTO [mart_fw].enbew_tk
           ([ZPT_ID]
           ,[ZPT_METERINGCODE]
		   ,[ABNAHMESTELLE]
           ,[KND_NR1]
           ,[KAT_NR]
           ,[KAT_BEZEICHNUNG]
           ,[PONAME]
           ,[STRASSE]
           ,[ORT]
           ,[2020]
           ,[2021]
           ,[2022]
           ,[2023]
           ,[2024]
           ,[KNG_BEZEICHNUNG]
           ,[KND_LETZTERECHNUNG]
           ,[KND_EINZUGDATUM]
           ,[KND_AUSZUGDATUM]
           ,[ABN_LTO_NR]
	)
	SELECT 
		PVT.ZPT_ID,
		ZP.ZPT_METERINGCODE,
		(CAST(ZP.ABN_PLZ AS VARCHAR) + ' ' + ZP.ABN_ORT + ', ' + ZP.ABN_STRASSE + ' ' + CAST(ZP.ABN_HAUSNR AS VARCHAR)) AS ABNAHMESTELLE,

		K.KND_NR1,

		K.KAT_NR,
		K.KAT_BEZEICHNUNG,
		K.PONAME,
		LTRIM(RTRIM(K.STRASSE + ' ' + K.HAUSNRVON + ' ' + K.HAUSNRVONZUS)) STRASSE,
		LTRIM(RTRIM(K.PLZ + ' ' + K.ORT)) ORT,
		PVT.[2020],
		PVT.[2021],
		PVT.[2022],
		PVT.[2023],
		PVT.[2024],
		K.KNG_BEZEICHNUNG,
		K.KND_LETZTERECHNUNG,
		K.KND_EINZUGDATUM,
		K.KND_AUSZUGDATUM,
		ZP.[ABN_LTO_NR]
	FROM
		(SELECT 
				VB.[ZPT_ID]
				,YEAR([KNV_ENDE]) JAHR
				,CAST([KNV_VERBRAUCHBER] AS INT) VB

			FROM 
				[EnergyDWH].[insert].[ENKNDVERBRAUCH] VB
			WHERE
				KNV_ENERGIEART <> 5 -- Keine Fernwärme
				AND PRZ_IDSTORNO IS NULL -- Nur nicht Stornierte Verbräuche
				AND KNV_ABGERECHNET is NOT NULL -- Nur Abgerechnete Verbräuche
		) P
		PIVOT (
			SUM(VB)
			FOR JAHR IN ([2013],[2014],[2015],[2016],[2017],[2018],[2019],[2020],[2021],[2022],[2023],[2024])
		) AS PVT
	JOIN
		[EnergyDWH].[insert].FW_ENZPT_ENABN ZP ON PVT.ZPT_ID = ZP.ZPT_ID
	LEFT JOIN
		#ZPT_ZU_KND TMP ON ZP.ZPT_ID = TMP.ZPT_ID
	LEFT JOIN
		EnergyDWH.[insert].[WILKEN_KUNDE_KAT_ADRESSE] K ON TMP.KND_ID = K.KND_ID

	--
	UPDATE mart_fw.enbew_tk
	SET
		[2020] = ISNULL([2020],0),
		[2021] = ISNULL([2021],0),
		[2022] = ISNULL([2022],0),
		[2023] = ISNULL([2023],0),
		[2024] = ISNULL([2024],0)


	-- HOUSEKEEPING
	IF OBJECT_ID('tempdb..#ZPT_ZU_KND', 'U') IS NOT NULL DROP TABLE #ZPT_ZU_KND


	--	---------------------------------------------------
	--	---------------------------------------------------
	END TRY
	--	---------------------------------------------------
	BEGIN CATCH
		-- Fehlermeldung zusammenbauen
		DECLARE @Message varchar(MAX) = CONCAT('Abbruch DWH: ', @SP_NAME, ' ### ',  ERROR_MESSAGE());


		-- Hier noch den Fehler eskalieren, damit abgebrochen wird
		THROW 51111, @Message, 1;

	END CATCH;
	--	---------------------------------------------------
	--	---------------------------------------------------





END

GO
