-- Object: mart_energieportfoliomanagement.dim_fernwaerme_produkte
-- Type  : VIEW





/*
	-- Test 

		select top 200 * from [mart_energieportfoliomanagement].[dim_fernwaerme_produkte] order by id_produkt
		

*/


CREATE view [mart_energieportfoliomanagement].[dim_fernwaerme_produkte] as

	with verbrauchsarten as (

		select 
			[id_produkt]
			,[id_verbrauchsart]
		from 
			[mart_energieportfoliomanagement].[fact_fernwaerme_abrechnungsmengen]
		group by
			[id_produkt]
			,[id_verbrauchsart]

	),

	produkte as (
	
		select distinct
			CAST(PRD_ID as int) id_produkt,
			ltrim(rtrim(PRD_BEZEICHNUNG)) as produkt,
			CAST(PRD_STATUS as int) as produkt_status,
			cast(PRD_GUELTIGVON as date) as produkt_gueltig_ab,
			cast(PRD_GUELTIGBIS as date) as produkt_gueltig_bis
		from
			raw.wilken_crprodukt p

		where
			PRD_ENERGIEART = 5
			and PRD_GUELTIGVON is not null

	)

	select
		p.id_produkt,
		produkt,
		produkt_status,
		produkt_gueltig_ab,
		produkt_gueltig_bis,
		id_verbrauchsart
	from 
		produkte p
	left join
		verbrauchsarten va on p.id_produkt = va.id_produkt
	union
		SELECT
			0 id_produkt,
			'unbekannt' produkt,
			1 produkt_status,
			null produkt_gueltig_ab,
			null produkt_gueltig_bis,
			null id_verbrauchsart

GO
