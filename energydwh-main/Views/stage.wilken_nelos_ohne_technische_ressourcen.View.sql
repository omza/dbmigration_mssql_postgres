-- Object: stage.wilken_nelos_ohne_technische_ressourcen
-- Type  : VIEW






/*


	change log
	----------
	17.06.2026	OMe	Abnahmestellen Status abfragen -> nur gültige Abnahmestellen berücksichtigen


	Test
	----
	select * from [stage].[wilken_nelos_ohne_technische_ressourcen] order by abnahmestelle_ort, abnahmestelle_strasse, abnahmestelle_hausnummer, abnahmestelle_hausnummer_zusatz

*/



CREATE view [stage].[wilken_nelos_ohne_technische_ressourcen] as


	-- Zugriffsweg über technische Ressourcen

	with adressen as (

		select distinct
			id_abn,
			abnahmestelle_adresse,
			abnahmestelle_straße,
			abnahmestelle_hausnummer,
			abnahmestelle_hausnummer_zusatz,
			abnahmestelle_plz,
			abnahmestelle_ort,
			abnahmestelle_status
		from
			core.zaehlpunkte
		where
			abnahmestelle_status = 1

	),

	nelo as (

		select 
			zpt.id_abn
			,link.[nlk_id] as id_nelo
			,nelok.nlk_code as nelo
			,nelok.nlk_zusatz as nelo_zusatz
			,cast([znlk_gueltigab] as date) as nelo_gueltig_ab
			,isnull(cast([znlk_gueltigbis] as date), '9999-12-31') as nelo_gueltig_bis

		from 
			[raw].[wilken_enzptnetzlokation] link

		join 
			raw.wilken_ennetzlokation nelok on nelok.nlk_id = link.nlk_id

		left join 
			core.zaehlpunkte zpt on zpt.id_zp = link.zpt_id
	
	)
	select distinct
		adr.id_abn,
		abnahmestelle_straße,
		isnull(abnahmestelle_hausnummer,-1) as abnahmestelle_hausnummer,
		isnull(abnahmestelle_hausnummer_zusatz,'') as abnahmestelle_hausnummer_zusatz,
		abnahmestelle_plz,
		abnahmestelle_ort,		
		nelo,
		'-' melo,
		adr.abnahmestelle_status
	from
		nelo nelo
	
	join
		adressen adr on adr.id_abn = nelo.id_abn
		
	where
		getdate() between nelo_gueltig_ab and nelo.nelo_gueltig_bis
		and nelo not in (
				select distinct nelo from [stage].[wilken_technische_ressourcen] where nelo is not null
			)


			


GO
