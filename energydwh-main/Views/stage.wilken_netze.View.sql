-- Object: stage.wilken_netze
-- Type  : VIEW








CREATE view [stage].[wilken_netze] as

	select 
		cast([net_id] as int) as id_netz
		,cast([mnd_id] as int) as id_mandant
		,cast([ene_id] as int) as id_energieart
		,cast([net_nr] as varchar(10)) as netz_nummer
		,cast([net_bezeichnung] as varchar(255)) as netz
		,cast([net_status] as int) as netz_status
		,cast([net_eigen] as int) as eigenes_netz
		,cast([net_grundversorger] as int) as grundversorger_netz
		,cast([net_kundennetz] as int) as kunden_netz
		,cast([net_angelegt] as datetime) as created_at
		,cast(isnull(net_geaendert,[net_angelegt]) as datetime) as changed_at
	from 
		[raw].[wilken_ennet]

	-- unbekannt
	union
	select 
		0 as id_netz
		,0 as id_mandant
		,0 as id_energieart
		,'' as netz_nummer
		,'unbekannt' as netz
		,1 as netz_status
		,1 as eigenes_netz
		,0 as grundversorger_netz
		,0 as kunden_netz
		,convert(datetime,'01.01.1900',104) as created_at
		,convert(datetime,'01.01.1900',104) as changed_at



GO
