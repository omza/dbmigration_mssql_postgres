-- Object: stage.wilken_lokationsbuendel
-- Type  : VIEW









/*
	ermittelt aus der raw tabellen die Lokationsbündel mit Zeitscheiben und Elementen

	08.07.2026	OMe	Initial
	10.07.2026	OMe	Es gibt n Elemente je Zeitscheibe
	13.07.2026	OMe	Lokationsbündel technische Ressource

	select * from [stage].[wilken_lokationsbuendel] where id_lokationsbuendel = 68863--id_ressource is not null order by id_lokationsbuendel

*/
CREATE view [stage].[wilken_lokationsbuendel] as

	with nelo as (

	select
		cast(lbe.[LOKBZ_ID] as int) as id_lokationsbuendel_zeitscheibe,
		cast(lbe.[NLK_ID] as int) as id_netzlokation,
		ltrim(rtrim(nle.NLK_CODE)) as netzlokation
	from
		[raw].[wilken_enlokbuendelelement] lbe

	join
		[raw].[wilken_enlokstrukturobjekt] lbo on lbe.LOKSO_ID = lbo.LOKSO_ID

	join
		raw.wilken_ennetzlokation nle on lbe.NLK_ID = nle.NLK_ID and nle.MND_ID = 1
	
	where
		lbo.[LOKSO_OBJEKTTYP] = 3
		and lbe.nlk_ID is not null

	),

	malo as (

		select
			cast(lbe.[LOKBZ_ID] as int) as id_lokationsbuendel_zeitscheibe,
			cast(lbo.LOKSO_EBENE as int) as id_ebene,
			max(cast(case when lbo.LOKSO_RICHTUNG = 1 then lbe.[MLK_ID] else null end as int)) as id_malo_bezug,
			max(cast(case when lbo.LOKSO_RICHTUNG = 2 then lbe.[MLK_ID] else null end as int)) as id_malo_einspeisung

		from
			[raw].[wilken_enlokbuendelelement] lbe

		join
			[raw].[wilken_enlokstrukturobjekt] lbo on lbe.LOKSO_ID = lbo.LOKSO_ID

	
		where
			lbo.[LOKSO_OBJEKTTYP] = 2
			and lbe.[MLK_ID] is not null	
	
		group by
			lbe.[LOKBZ_ID],
			lbo.LOKSO_EBENE

	),

	ressource as (

		select
			cast(lbe.[LOKBZ_ID] as int) as id_lokationsbuendel_zeitscheibe,
			cast(lbe.TRE_ID as int) as id_ressource,
			cast(lbo.LOKSO_EBENE as int) as id_ebene,
			cast(lbo.LOKSO_RICHTUNG as int) as id_richtung
		from
			[raw].[wilken_enlokbuendelelement] lbe

		join
			[raw].[wilken_enlokstrukturobjekt] lbo on lbe.LOKSO_ID = lbo.LOKSO_ID

	
		where
			lbo.[LOKSO_OBJEKTTYP] = 4
			and lbe.TRE_ID is not null

	),

	melo as (

		select
			cast(lbe.[LOKBE_ID] as int) as id_lokationsbuendel_element,
			cast(lbe.[LOKBZ_ID] as int) as id_lokationsbuendel_zeitscheibe,
			cast(lbe.ZPT_ID_MELO as int) as id_zp,
			cast(lbo.LOKSO_EBENE as int) as id_ebene,
			cast(lbo.LOKSO_RICHTUNG as int) as id_richtung,
			cast(lbo.LOKSO_MELOFUNKTION as int) as id_melofunktion,
			cast(isnull(lbe.[LOKBE_GEAENDERT],[LOKBE_ANGELEGT]) as date) as changed_at
		from
			[raw].[wilken_enlokbuendelelement] lbe

		join
			[raw].[wilken_enlokstrukturobjekt] lbo on lbe.LOKSO_ID = lbo.LOKSO_ID

	
		where
			lbo.[LOKSO_OBJEKTTYP] = 1
			and lbe.ZPT_ID_MELO is not null

	),

	element as (

		select
			zp.*,
			nl.id_netzlokation,
			nl.netzlokation,
			ml.id_malo_bezug,
			ml.id_malo_einspeisung,
			res.id_ressource

		from
			melo zp

		left join
			nelo nl on zp.id_lokationsbuendel_zeitscheibe = nl.id_lokationsbuendel_zeitscheibe

		left join
			malo ml 
		on 
			zp.id_lokationsbuendel_zeitscheibe = ml.id_lokationsbuendel_zeitscheibe
			and zp.id_ebene = ml.id_ebene

		left join
			ressource res 
		on 
			zp.id_lokationsbuendel_zeitscheibe = res.id_lokationsbuendel_zeitscheibe
			--and case when zp.id_richtung = 3 then 1 else zp.id_richtung end = res.id_richtung
			and zp.id_ebene = res.id_ebene
	)

	select distinct

		be.id_lokationsbuendel_element,
		cast(bz.LOKBZ_ID as int) as id_lokationsbuendel_zeitscheibe,
		cast(b.LOKB_ID as int) as id_lokationsbuendel,
		ltrim(rtrim(b.LOKB_BEZEICHNUNG)) as lokationsbuendel,
		left(ltrim(rtrim(b.LOKB_INFO)),100) as lokationsbuendel_info,
		cast(s.LOKS_ID as int) as id_lokationsbuendelstruktur,
		cast(b.ABN_ID as int) as id_abn,

		--
		be.id_netzlokation,
		be.netzlokation,

		be.id_zp,
		be.id_malo_bezug,
		be.id_malo_einspeisung,

		isnull(be.id_ressource,0) as id_ressource,

		be.id_melofunktion,

		case 
			when be.id_melofunktion = 1 then 'Netzuebergabe'
			when be.id_melofunktion = 2 then 'Hinterschaltung'
			when be.id_melofunktion = 3 then 'Differenzmessung'
			else 'unbekannt'
		end as melofunktion,

		be.id_ebene,
		be.id_richtung,
		case 
			when be.id_richtung = 1 then 'Verbrauch'
			when be.id_richtung = 2 then 'Erzeugung'
			when be.id_richtung = 3 then 'Verbrauch und Erzeugung'
			else 'unbekannt'
		end as richtung,

		--
		cast(bz.[LOKBZ_GUELTIGAB] as date) as gueltig_ab,
		cast(isnull(bz.[LOKBZ_GUELTIGBIS], '9999-12-31') as date) as gueltig_bis,
		cast(bz.[LOKBZ_STATUS] as int) as id_lokationsbuendel_status,
		case 
			when bz.[LOKBZ_STATUS] = 1 then 'Aktiv'
			when bz.[LOKBZ_STATUS] = 2 then 'Entwurf'
			when bz.[LOKBZ_STATUS] = 3 then 'Storniert'
			else 'unbekannt'
		end as lokationsbuendel_status,

		cast(b.LOKB_ANGELEGT as date) as created_at,
		cast(
				(SELECT 
					MAX(maxdate)
				 FROM (VALUES (b.LOKB_GEAENDERT),(bz.LOKBZ_GEAENDERT),(be.changed_at)) AS AllDates(maxdate)
				) 
			as date) as changed_at

	from
		raw.wilken_enlokationsbuendel b

	join
		raw.wilken_enlokationsbuendelstruktur s on b.LOKB_STRUKTURCODE = s.LOKS_STRUKTURCODE

    join
		[raw].[wilken_enlokbuendelzeit] bz on b.LOKB_ID = bz.LOKB_ID

	join
		element be on cast(bz.LOKBZ_ID as int) = be.id_lokationsbuendel_zeitscheibe



GO
