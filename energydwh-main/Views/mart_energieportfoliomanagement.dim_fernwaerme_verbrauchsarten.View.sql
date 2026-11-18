-- Object: mart_energieportfoliomanagement.dim_fernwaerme_verbrauchsarten
-- Type  : VIEW




/*
	-- Test 

		select top 200 * from [mart_energieportfoliomanagement].[dim_fernwaerme_verbrauchsarten] order by id_verbrauchsart
		

*/


CREATE view [mart_energieportfoliomanagement].[dim_fernwaerme_verbrauchsarten] as

	select 
		cast(VBA_NR as int) id_verbrauchsart,
		VBA_BEZEICHNUNG verbrauchsart,
		VBA_EINHEIT as einheit
	from 
		raw.wilken_envba 
	where 
		MND_ID = 1 
		and VBA_ENERGIEART = 5 
		and VBA_STATISTIKRELEVANT = 1
	union
	select
		0 id_verbrauchsart,
		'unbekannt' verbrauchsart,
		null einheit

GO
