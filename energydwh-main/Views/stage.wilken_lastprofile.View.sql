-- Object: stage.wilken_lastprofile
-- Type  : VIEW
/*

	changelog
	24.06.2026	OMe	Initial

	test
	select * from [stage].[wilken_lastprofile]  order by id_lastprofil

*/
CREATE view [stage].[wilken_lastprofile] as

	select 
		cast([LPR_ID] as int) as id_lastprofil
		,cast([mnd_id] as int) as id_mandant
		,cast([ene_id] as int) as id_energieart
		,cast([LPR_NR] as int) as lastprofil_nummer
		,cast([LPR_EDICODE] as varchar(10)) as edicode
		,cast([lpr_bezeichnung] as varchar(255)) as lastprofil
		,cast(LPR_AKTIV as int) as lastprofil_aktiv
		,cast([lpr_angelegt] as datetime) as created_at
		,cast(isnull(lpr_geaendert,[lpr_angelegt]) as datetime) as changed_at
	from 
		[raw].[wilken_enlastprofil]

	union
	-- unbekannt
	select
		-1 as id_lastprofil
		,0 as id_mandant
		,0 as id_energieart
		,0 as lastprofil_nummer
		,'' as edicode
		,'unbekannt' as lastprofil
		,0 as lastprofil_aktiv
		,convert(datetime,'1900-01-01',120) as created_at
		,convert(datetime,'1900-01-01',120) as changed_at		




GO
