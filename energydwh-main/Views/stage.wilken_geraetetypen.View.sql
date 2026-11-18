-- Object: stage.wilken_geraetetypen
-- Type  : VIEW


/*

	Change Log
	----------

	15.12.2025 OMe	Typ Geräteinfosatz hinzufügen


	Test
	----
	
	select * from [stage].[wilken_geraetetypen] order by wilken_mnd_id, wilken_zpt_energieart

*/

CREATE view [stage].[wilken_geraetetypen] as

	select  
		ztp.MND_ID as wilken_mnd_id,
		ztp.ZTP_NR as wilken_ztp_nr,
		ztp.ZTP_ENERGIEART as wilken_zpt_energieart,
		ztp.ZTP_Bezeichnung as geraetetyp,
		ger.GER_BEZEICHNUNG as geraeteart,
		ger.GER_ID as wilken_ger_id,
		ztp.ZTP_STATUS as wilken_zpt_status,
		ztp.ZTP_ANGELEGT as created_at,
		isnull(ztp.ZTP_GEAENDERT, ztp.ZTP_ANGELEGT) as changed_at
		-- 14.08.2025
		,ng.ZNE_BEZEICHNUNG as nenngroesse
	from 
		raw.wilken_enzaehlertyp ztp
	join
		raw.wilken_engeraeteart ger on ztp.ZTP_GERAETEGRUNDTYP = ger.GER_GERAETEGRUNDTYP and ger.GER_ID <> 99
	left join
		raw.wilken_enzaenenngroesse ng on ztp.ZTP_NENNGROESSE = ng.ZNE_NR and ztp.MND_ID = ng.MND_ID and ztp.ZTP_ENERGIEART = ng.ENE_ID and ztp.MND_ID = ng.MND_ID

	union --Geräteinfosatz

	select  
		1 as wilken_mnd_id,
		'INFO' as wilken_ztp_nr,
		0 as wilken_zpt_energieart,
		'Geraeteinfosatz' as geraetetyp,
		null as geraeteart,
		null as wilken_ger_id,
		1 as wilken_zpt_status,
		CONVERT(date, '01.01.1900', 104) as created_at,
		CONVERT(date, '01.01.1900', 104) as changed_at
		-- 14.08.2025
		,null as nenngroesse




GO
