-- Object: mart_energieportfoliomanagement.fact_fernwaerme_kunden_produkt_zeitraum
-- Type  : VIEW











/*
	-- Test 

		select * from [mart_energieportfoliomanagement].[fact_fernwaerme_kunden_produkt_zeitraum] where kundenname <> ''
		--order by id_kunde, jahr
		

*/


CREATE view [mart_energieportfoliomanagement].[fact_fernwaerme_kunden_produkt_zeitraum] as


	with kundenstatus as (

		select distinct
			[wert] as id_kundenstatus
			,[definition] as kundenstatus
		from 
			[core].[schluesseldefinition]
		where
			feldname = 'id_kundenstatus'

	), fernwaerme as (

		select distinct
			lkz.id_zp,
			lkz.id_kunde,
			lkz.id_link_messeinheit,
			p.PRD_ID as id_produkt,
			case when cast(p.PRD_ID as int) in (14541, 14532, 14512) then 1 else 0 end eigenverbrauch,
			v.GPVG_BEGINN as vertrag_start,
			v.GPVG_ENDE as vertrag_ende,
			v.GPVG_STATUS as vertrag_status

		from
			core.link_kunde_zaehlpunkt lkz
		join
			raw.wilken_crgpvertraglink l on lkz.id_link_messeinheit = l.GPVL_FKID
		join
			raw.wilken_crgpvertrag v on l.GPVG_ID = v.GPVG_ID
		join
			raw.wilken_crprodukt p on v.PRD_ID = p.PRD_ID --and GETDATE() between v.GPVG_BEGINN and isnull(v.GPVG_ENDE,getdate())
		where
			lkz.id_mandant = 1
			and p.PRD_ENERGIEART = 5
			--and v.GPVG_STATUS <> 0
	
	), kunden_zeitscheiben as (

	select
		id_zp,
		k.id_kunde,
		id_link_messeinheit,
		kunden_nummer,
		k.person_typ,
		case when k.person_typ = 'N' or charindex(LOWER(geschaeftspartner_name),'leer') > 0 then '' else geschaeftspartner_name end as kundenname,
		id_kundengruppe,
		id_kundenkategorie,
		fk.id_produkt,
		cast(einzugsdatum as date) as einzug,
		cast(auszugsdatum as date) as auszug,
		k.id_kundenstatus,
		ks.kundenstatus,
		fk.eigenverbrauch,
		ROW_NUMBER() over (partition by fk.id_link_messeinheit, fk.id_produkt order by valid_to desc) as rang
	from
		core.kunden k
	join
		fernwaerme fk on k.id_kunde = fk.id_kunde
	left join
		kundenstatus ks on k.id_kundenstatus = ks.id_kundenstatus
	where
		k.unbundling_art in ('Vertrieb','Netz und Vertrieb')

	), 
	
	zeitraum as
	(
		select distinct
			YEAR(tag) jahr,
			tag
		from
			core.kalender
		where
			tag between 
					(select MIN(einzug) from kunden_zeitscheiben)
				and
					(select MAX(auszug) from kunden_zeitscheiben)
			
	)



	-- letzte Zeitscheibe je Kunde
	select distinct
		kzs.id_zp,
		kzs.id_kunde,
		id_link_messeinheit,
		kunden_nummer,
		kundenname,
		person_typ,
		id_kundengruppe,
		id_kundenkategorie,
		id_produkt,
		einzug,
		auszug,
		id_kundenstatus,
		kundenstatus,
		eigenverbrauch,
		[meteringcode] as melo,
		[abnahmestelle_adresse],
		[abnahmestelle_lat],
		[abnahmestelle_lon],
		zr.jahr
	from 
		kunden_zeitscheiben kzs
	join
		zeitraum zr on tag between kzs.einzug and isnull(kzs.auszug,getdate())
	left join
		core.zaehlpunkte zp on kzs.id_zp = zp.id_zp and zp.id_mandant = 1 and zp.id_energieart = 5 

	where
		rang = 1



GO
