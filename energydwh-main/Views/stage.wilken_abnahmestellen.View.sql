-- Object: stage.wilken_abnahmestellen
-- Type  : VIEW


/*

	change log
	----------
	23.09.2026	OMe	initial


	test
	---
	select * from [stage].[wilken_abnahmestellen] 

*/
CREATE view [stage].[wilken_abnahmestellen] as

	SELECT 

		cast(ABN.ABN_ID as int) as id_abn,
		cast(isnull(ABN.ABN_STATUS,-1) as int) as abnahmestelle_status,

		ABN.MND_ID as id_mandant,
		ABN_STRASSE + ' ' + ISNULL(CAST(ABN_HAUSNR AS VARCHAR),'') + ISNULL(CAST(ABN_HAUSUNTERNR AS VARCHAR),'') + ', ' + CAST(ABN_PLZ AS VARCHAR) + ' ' + ABN_ORT abnahmestelle_adresse,

		ABN_STRASSE as abnahmestelle_straße,
		CAST(ABN_HAUSNR as INT) as abnahmestelle_hausnummer,
		ABN_HAUSUNTERNR as abnahmestelle_hausnummer_zusatz,
		CAST(ABN_PLZ AS VARCHAR(10)) as abnahmestelle_plz,
		ABN_ORT as abnahmestelle_ort,
		ABN_LTO_NR ablesetour_nr,

		cast([ABN_ANGELEGT] as datetime) as created_at,
		cast(isnull([ABN_GEAENDERT],[ABN_ANGELEGT]) as datetime) as changed_at

	FROM
		[raw].[wilken_enabn] ABN
	


GO
