-- Object: stage.wilken_zaehlverfahren
-- Type  : VIEW
/*

	changelog
	24.06.2026	OMe	Initial

	test
	select * from [stage].[wilken_zaehlverfahren]  order by id_mandant, id_zaehlverfahren

*/
CREATE view [stage].[wilken_zaehlverfahren] as

	select 
		cast([mnd_id] as int) as id_mandant
		,cast(ZVF_NR as int) as id_zaehlverfahren

		,cast([ene_id] as int) as id_energieart
		,cast([ZVF_EDICODE] as varchar(3)) as edicode
		,cast([ZVF_BEZEICHNUNG] as varchar(60)) as zaehlverfahren
		,cast([zvf_angelegt] as datetime) as created_at
		,cast(isnull(zvf_geaendert,[zvf_angelegt]) as datetime) as changed_at
	from 
		[raw].[wilken_enzaehlverfahren]

	union
	-- unbekannt
	select distinct
		cast([mnd_id] as int) as id_mandant
		,-1 as id_zaehlverfahren

		,0 as id_energieart
		,'' as edicode
		,'unbekannt' as zaehlverfahren
		,convert(datetime,'1900-01-01',120) as created_at
		,convert(datetime,'1900-01-01',120) as changed_at		
	from
		[raw].[wilken_enzaehlverfahren]



GO
