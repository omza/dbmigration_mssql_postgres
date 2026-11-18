-- Object: stage.wilken_spannungsebenen
-- Type  : VIEW


/*

	select * from [stage].[wilken_spannungsebenen]


*/

CREATE view [stage].[wilken_spannungsebenen] as

	select 
		cast([SPE_NR] as int) as id_spannungsebene
		,cast([mnd_id] as int) as id_mandant
		,cast([ene_id] as int) as id_energieart
		,cast([SPE_BEZEICHNUNG] as varchar(255)) as spannungsebene
		,cast([SPE_EDICODE] as varchar(10)) as edicode	
		,cast([SPE_ANGELEGT] as datetime) as created_at
		,cast(isnull([SPE_GEAENDERT],[SPE_ANGELEGT]) as datetime) as changed_at
	from 
		[raw].[wilken_enspannungsebene]

	-- unbekannt
	union
	select distinct
		-1 as id_spannungsebene
		,cast([mnd_id] as int) as id_mandant
		,0 as id_energieart
		,'unbekannt' as spannungsebene
		,'' as edicode
		,convert(datetime,'01.01.1900',104) as created_at
		,convert(datetime,'01.01.1900',104) as changed_at
	from
		[raw].[wilken_enspannungsebene]

GO
