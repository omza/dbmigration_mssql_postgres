-- Object: dwh.LOAD_MART_FW_fw_zp_verbrauch
-- Type  : SQL_STORED_PROCEDURE

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dwh].[LOAD_MART_FW_fw_zp_verbrauch]

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

	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[mart_fw].[fw_zp_verbrauch]') AND type in (N'U'))
		DROP TABLE [mart_fw].[fw_zp_verbrauch]


	CREATE TABLE [mart_fw].[fw_zp_verbrauch](
		[METERINGCODE] [varchar](33) NOT NULL,
		[ENERGIEART] VARCHAR(50) NOT NULL,
		[ABNAHMESTELLE] [varchar](250) NULL,
		[ABLESETOUR_NR] [decimal](5, 0) NULL,
		[VERTRAGSKONTO] [varchar](20) NULL,
		[GESCHAEFTSPARTNER] [varchar](22) NULL,
		[KUNDENKATEGORIE] [varchar](50) NULL,
		[KUNDENGRUPPE] [varchar](50) NULL,
		[GP_NAME] [varchar](250) NULL,
		[KUNDENADRESSE] [varchar](250) NULL,
		[EINZUG] [date] NULL,
		[AUSZUG] [date] NULL,
		[ZAEHLER_NUMMER] [varchar](20) NOT NULL,
		[ZAEHLERTYP] [varchar](60) NOT NULL,
		[EICHUNG] [decimal](4, 0) NULL,
		[NAECHSTE_EICHUNG] [decimal](4, 0) NULL,
		[GERAETEPLATZ] [varchar](255) NOT NULL,
		[GERAETEART] [varchar](40) NOT NULL,
		[EINBAU] [date] NOT NULL,
		[AUSBAU] [date] NULL,
		[2020] [int]  NULL,
		[2021] [int]  NULL,
		[2022] [int]  NULL,
		[2023] [int]  NULL,
		[2024] [int]  NULL
	) ON [PRIMARY]




	/*
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
		) KND
	WHERE
		LFD_NR = 1
	*/



	-- Einfügen

	INSERT INTO [mart_fw].[fw_zp_verbrauch]
           ([METERINGCODE]
           ,[ENERGIEART]
           ,[ABNAHMESTELLE]
           ,[ABLESETOUR_NR]
           ,[VERTRAGSKONTO]
           ,[GESCHAEFTSPARTNER]
           ,[KUNDENKATEGORIE]
           ,[KUNDENGRUPPE]
           ,[GP_NAME]
           ,[KUNDENADRESSE]
           ,[EINZUG]
           ,[AUSZUG]
           ,[ZAEHLER_NUMMER]
           ,[ZAEHLERTYP]
           ,[EICHUNG]
           ,[NAECHSTE_EICHUNG]
           ,[GERAETEPLATZ]
           ,[GERAETEART]
           ,[EINBAU]
           ,[AUSBAU]
           ,[2020]
           ,[2021]
           ,[2022]
           ,[2023]
           ,[2024]
	)
	SELECT 
		METERINGCODE,
		ea.energieart ENERGIEART,
		ltrim(rtrim(left(zp.abnahmestelle_adresse,250))) ABNAHMESTELLE,
		ABLESETOUR_NR,
		K.kunden_nummer  VERTRAGSKONTO,
		K.geschaeftspartner_nummer GESCHAEFTSPARTNER,
		kk.kundenkategorie KUNDENKATEGORIE,
		kg.kundengruppe KUNDENGRUPPE,
		K.geschaeftspartner_name GP_NAME,
		ltrim(rtrim(left(K.strasse + ' ' + Hausnummer + hausnummer_zusatz + ',' + plz + ' ' + ort,250)))  KUNDENADRESSE,
		K.einzugsdatum EINZUG,
		K.auszugsdatum AUSZUG,
		Z.ZAE_NR ZAEHLER_NUMMER,
		ZTYP.ZTP_BEZEICHNUNG ZAEHLERTYP,
		Z.ZAE_EICHJAHR EICHUNG,
		Z.ZAE_NAECHSTESEICHJAHR NAECHSTE_EICHUNG,
		GPLATZ.GERP_BEZEICHNUNG GERAETEPLATZ,
		GART.GER_BEZEICHNUNG GERAETEART,
		ZPZ.ZPG_EINBAUDATUM EINBAU,
		ZPZ.ZPG_AUSBAUDATUM AUSBAU,
		PVT.[2020],
		PVT.[2021],
		PVT.[2022],
		PVT.[2023],
		PVT.[2024]
	FROM
		(SELECT 
				VB.[ZPT_ID]
				,YEAR([KNV_ENDE]) JAHR
				,CAST([KNV_VERBRAUCHBER] AS INT) VB

			FROM 
				[raw].[wilken_enkndverbrauchabgr] VB
			WHERE
				KNV_BUC_ABGRKENNZEICHEN IN (90,91,92) -- nach Markus Sass
				AND PRZ_IDSTORNO IS NULL -- Nur nicht Stornierte Verbräuche
		) P
		PIVOT (
			SUM(VB)
			FOR JAHR IN ([2013],[2014],[2015],[2016],[2017],[2018],[2019],[2020],[2021],[2022],[2023],[2024])
		) AS PVT
	JOIN
		core.zaehlpunkte ZP ON PVT.ZPT_ID = ZP.id_zp
	JOIN
		core.link_kunde_zaehlpunkt MES ON ZP.id_zp = MES.id_zp AND ZP.id_mandant = MES.id_mandant and GETDATE() between MES.valid_from and MES.valid_to
	JOIN
		core.kunden K ON MES.id_kunde = K.id_kunde
	JOIN
		core.kundengruppen kg ON K.id_mandant = kg.id_mandant and K.id_kundengruppe = kg.id_kundengruppe
	JOIN
		core.kundenkategorie kk ON K.id_mandant = kk.id_mandant and K.id_kundenkategorie = kk.id_kundenkategorie
	JOIN
		core.energiearten ea on zp.id_energieart = ea.id_energieart
	JOIN
		[raw].[wilken_enzptgeraet] ZPZ ON ZP.id_zp = ZPZ.ZPT_ID AND ZP.id_mandant = ZPZ.MND_ID
	JOIN
		[raw].[wilken_enzaehler] Z ON ZPZ.ZAE_ID = Z.ZAE_ID AND ZP.id_mandant = Z.MND_ID AND ZP.id_energieart = Z.ZAE_ENERGIEART
	JOIN
		[raw].[wilken_engeraeteplatz] GPLATZ ON ZPZ.GERP_ID = GPLATZ.GERP_ID AND ZP.id_mandant = GPLATZ.MND_ID
	JOIN
		[raw].[wilken_engeraeteart] GART ON Z.GER_ID = GART.GER_ID
	JOIN
		[raw].[wilken_enzaehlertyp] ZTYP ON Z.ZTP_NR = ZTYP.ZTP_NR AND ZP.id_mandant = ZTYP.MND_ID AND ZP.id_energieart = ZTYP.ZTP_ENERGIEART
	where 
		ZP.id_energieart = 5
	
	-- Nullwerte ersetzen
	UPDATE mart_fw.[fw_zp_verbrauch]
	SET
		[2020] = ISNULL([2020],0),
		[2021] = ISNULL([2021],0),
		[2022] = ISNULL([2022],0),
		[2023] = ISNULL([2023],0),
		[2024] = ISNULL([2024],0)


	-- HOUSEKEEPING
	--IF OBJECT_ID('tempdb..#ZPT_ZU_KND', 'U') IS NOT NULL DROP TABLE #ZPT_ZU_KND


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
