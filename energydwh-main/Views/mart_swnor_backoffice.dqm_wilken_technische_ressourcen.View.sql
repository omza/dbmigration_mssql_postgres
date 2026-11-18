-- Object: mart_swnor_backoffice.dqm_wilken_technische_ressourcen
-- Type  : VIEW






/*
	select * from [mart_swnor_backoffice].[dqm_wilken_technische_ressourcen] order by id_ressource, fehlerbild

*/



CREATE view [mart_swnor_backoffice].[dqm_wilken_technische_ressourcen] as

	

	with id_ressource_doppelt as (

		-- Fehlerbild doppelt vergebene Ressourcen ID mit unterschiedlichen melo
		select 
			id_ressource
		from 
			stage.wilken_technische_ressourcen
		group by
			id_ressource
		having
			count(*)>1
			and count(distinct melo) > 1

	), id_ressource_doppelt_nelo as (

		-- Fehlerbild doppelt vergebene Ressourcen ID mit unterschiedlichen Nelos
		select 
			id_ressource
		from 
			stage.wilken_technische_ressourcen
		group by
			id_ressource
		having
			count(*)>1
			--and count(distinct melo) = 1
			and count(distinct nelo) > 1

	), speicher_ohne_malos as (

		select distinct
			id_ressource
		from
			stage.wilken_technische_ressourcen
		where
			ressource_nutzungsart = 'Speicher'
			and (
				malo_bezug is null
				or malo_einspeisung is null
			)
		

	)


	-- Fehlerbild doppelt vergebene Ressourcen ID mit unterschiedlichen melo
	select
		'Ressourcen ID an unterschiedlichen Messlokationen' as fehlerbild
		,r.*
	
	from
		stage.wilken_technische_ressourcen r
	
	join
		id_ressource_doppelt d on r.id_ressource = d.id_ressource

	-- gleiche id_ressource ist mehreren Nelos zugeordnet
	union

	select
		'Mehrere Netzlokationen an einer Abnahmestelle' as fehlerbild
		,r.*
	
	from
		stage.wilken_technische_ressourcen r
	
	join
		id_ressource_doppelt_nelo d on r.id_ressource = d.id_ressource	

	-- Speicher mit fehlender Malo
	union

	select
		'Speicher hat nicht beide Malos gepflegt' as fehlerbild
		,r.*
	
	from
		stage.wilken_technische_ressourcen r
	
	join
		speicher_ohne_malos d on r.id_ressource = d.id_ressource	



GO
