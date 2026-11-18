-- Object: stage.wilken_enzpt_enabn
-- Type  : VIEW


create view [stage].[wilken_enzpt_enabn] as


	SELECT 
		ZP.ZPT_ID,
		ZP.MND_ID,
		ZPT_METERINGCODE METERINGCODE,
		ZPT_ENERGIEART ENERGIEART,
		ABN_STRASSE + ' ' + ISNULL(CAST(ABN_HAUSNR AS VARCHAR),'') + ISNULL(CAST(ABN_HAUSUNTERNR AS VARCHAR),'') + ', ' + CAST(ABN_PLZ AS VARCHAR) + ' ' + ABN_ORT ABNAHMESTELLE,
		ABN_LTO_NR ABLESETOUR_NR
	FROM
		[EnergyDWH].raw.wilken_enzpt ZP
	JOIN
		[raw].[wilken_enabn] ABN ON ZP.ABN_ID = ABN.ABN_ID

GO
