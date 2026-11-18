-- Object: mart_swnor_backoffice.dqm_wilken_nelos_abnahmestellen
-- Type  : VIEW





/*
	select * from [mart_swnor_backoffice].[dqm_wilken_nelos_abnahmestellen] order by fehlerbild, [abnahmestelle_straße]
			,[abnahmestelle_hausnummer]
			,[abnahmestelle_hausnummer_zusatz]
			,[abnahmestelle_plz]
			,[abnahmestelle_ort]

*/



CREATE view [mart_swnor_backoffice].[dqm_wilken_nelos_abnahmestellen] as

	

	with nelo_doppelt as (

		-- Fehlerbild doppelt vergebene Nelo an unterschiedlichen abnahmestellen
		select 
			nelo
		from
			stage.[wilken_nelos_ohne_technische_ressourcen]
		where
			abnahmestelle_status = 1
		group by
			nelo
		having count(*) > 1

	), abn_mehrere_nelos as (

		select 
			[abnahmestelle_straße]
			,[abnahmestelle_hausnummer]
			,[abnahmestelle_hausnummer_zusatz]
			,[abnahmestelle_plz]
			,[abnahmestelle_ort]
		from
			stage.[wilken_nelos_ohne_technische_ressourcen]
		where
			abnahmestelle_status = 1
		group by
			[abnahmestelle_straße]
			,[abnahmestelle_hausnummer]
			,[abnahmestelle_hausnummer_zusatz]
			,[abnahmestelle_plz]
			,[abnahmestelle_ort]
		having count(distinct nelo) > 1

	)
	-- doppelt vergebene Nelo an unterschiedlichen abnahmestellen
	select
		'Nelo an unterschiedlichen Abnahmestellen' as fehlerbild
		,r.*
	
	from
		stage.[wilken_nelos_ohne_technische_ressourcen] r
	
	join
		nelo_doppelt d on r.nelo = d.nelo

	union

	-- Abnahmestellen mit unterschiedlichen Nelos
	select
		'Mehrere Nelos an einer Abnahmestelle' as fehlerbild
		,r.*
	
	from
		stage.[wilken_nelos_ohne_technische_ressourcen] r
	
	join
		abn_mehrere_nelos d 
	on 
			r.[abnahmestelle_straße] = d.[abnahmestelle_straße]
			and r.[abnahmestelle_hausnummer] = d.[abnahmestelle_hausnummer]
			and r.[abnahmestelle_hausnummer_zusatz] = d.[abnahmestelle_hausnummer_zusatz]
			and r.[abnahmestelle_plz] = d.[abnahmestelle_plz]
			and r.[abnahmestelle_ort] = d.[abnahmestelle_ort]


GO
