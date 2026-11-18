-- Object: stage.wilken_lokationsbuendelstruktur
-- Type  : VIEW


/*
	ermittelt aus der raw tabelle die Lokationsbündelstruktur als Schlüsseltabelle (def)

	09.07.2026	OMe	Initial
	

	select *  from [stage].[wilken_lokationsbuendelstruktur] 

*/

CREATE view [stage].[wilken_lokationsbuendelstruktur] as


	select

		cast(s.LOKS_ID as int) as id_lokationsbuendelstruktur
		,ltrim(rtrim([LOKS_STRUKTURCODE])) as lokationsbuendelstruktur_code
		,ltrim(rtrim([LOKS_BEZEICHNUNG])) as lokationsbuendelstruktur_bezeichnung
		,cast([LOKS_GUELTIGAB] as date) as gueltig_ab
		,cast(isnull([LOKS_GUELTIGBIS],'9999-12-31') as date) as gueltig_bis
		,cast([LOKS_ANGELEGT] as date) as created_at
		,cast(isnull([LOKS_GEAENDERT],[LOKS_ANGELEGT]) as date) as changed_at
	from

		raw.wilken_enlokationsbuendelstruktur s 


GO
