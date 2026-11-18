-- Object: mart_energiemanagement.wtg_glasfaser_netzinfrastruktur
-- Type  : VIEW





/*

	wtg_glasfaser_netzinfrastruktur

	select * from [mart_energiemanagement].[wtg_glasfaser_netzinfrastruktur]

*/


CREATE view [mart_energiemanagement].[wtg_glasfaser_netzinfrastruktur] as


	WITH GlasfaserHierarchy AS (

		-- Anchor member: Select the top-level
		SELECT 
			nk.id_netz,
			id_knoten_parent as [id_knoten], 
			null as id_knoten_parent,
			nk.knoten_name,
			0 AS Level
		FROM
			core.netz_hierarchie h
		join
			core.netz_knoten nk on h.id_knoten_parent = nk.id_knoten
		WHERE 
			id_knoten_parent = 0
			and nk.id_netz = 1

		UNION ALL

		-- Recursive member: Select employees reporting to the previous level
		SELECT
			nk.id_netz,
			e.[id_knoten],
			e.id_knoten_parent,
			nk.knoten_name,
			eh.Level + 1
		FROM 
			core.netz_hierarchie e
		INNER JOIN 
			GlasfaserHierarchy eh ON e.id_knoten_parent = eh.id_knoten
		join
			core.netz_knoten nk on e.id_knoten = nk.id_knoten and eh.id_netz = nk.id_netz
	),

	ebenen as (

		select
			eb0.id_netz
			,eb0.id_knoten as ebene0_id_knoten
			,eb0.knoten_name as ebene0_knoten_name

			,eb1.id_knoten as ebene1_id_knoten
			,eb1.knoten_name as ebene1_knoten_name

			,eb2.id_knoten as ebene2_id_knoten
			,eb2.knoten_name as ebene2_knoten_name

			,nk.knoten_beschreibung
			,nk.knoten_straße
			,ISNULL(cast(nk.knoten_hausnummer as varchar), nk.knoten_hausnummer_zusatz) as hausnummer
			,nk.knoten_plz
			,nk.knoten_ort
		
		from
			(select id_netz, id_knoten, knoten_name from GlasfaserHierarchy where Level = 0) eb0
		join
			(select id_netz, id_knoten, id_knoten_parent, knoten_name from GlasfaserHierarchy where Level = 1) eb1 on eb0.id_knoten = eb1.id_knoten_parent
		join
			(select id_netz, id_knoten, id_knoten_parent, knoten_name from GlasfaserHierarchy where Level = 2) eb2 on eb1.id_knoten = eb2.id_knoten_parent
		join
			core.netz_knoten nk on eb2.id_knoten = nk.id_knoten 

	)

	select distinct
		n.id_mandant,
		e.*,
		--p.Messlokation_Melo as melo_popliste,

	
		lw.faktor,

		ea.energieart,
		lw.id_zp,
		zp.meteringcode as melo,
		zp.abnahmestelle_adresse,
	
		lkz.id_link_messeinheit,
	
		lkz.vertragsart,
		lkz.id_kunde,
		lkz.valid_from,
		lkz.valid_to,
		lkz.id_lieferant,
		l.lieferant,
		k.kunden_nummer as kundennummer,
		geschaeftspartner_name,
		person_zusatz,
		p.Z_hler_NR as zaehlernummer_popliste,
		g.geraetenummer,
		lzg.id_geraet,
		lzg.einbaudatum,
		lzg.ausbaudatum,
		g.id_geraeteart,
		g.id_geraetetyp,
		g.id_standardgeraetetyp,
		g.zaehler_energierichtungen
	from 
		ebenen e
	join
		core.netze n on e.id_netz = n.id_netz
	left join
		raw.popstandorte p on e.ebene2_knoten_name = p.Bezeichnung
	left join
		[core].[link_netz_knoten_verbraucher] lw on e.ebene2_id_knoten = lw.id_knoten
	left join
		core.zaehlpunkte zp on lw.id_zp = zp.id_zp and zp.id_mandant = 1
	LEFT join
		core.energiearten ea on zp.id_energieart = ea.id_energieart
	left join
		core.link_kunde_zaehlpunkt lkz on zp.id_zp = lkz.id_zp and lkz.active = 1 and zp.id_mandant = lkz.id_mandant and lkz.id_vertragsart not in (3)
	left join
		core.kunden k on lkz.id_kunde = k.id_kunde and lkz.id_mandant = k.id_mandant
	left join
		core.lieferanten l on lkz.id_lieferant = l.id_lieferant
	left join
		core.link_zaehlpunkt_geraet lzg on lzg.id_zp = zp.id_zp and lzg.active = 1  and zp.id_mandant = lzg.id_mandant
	left join
		core.geraete g on lzg.id_geraet = g.id_geraet and lzg.id_mandant = g.id_mandant


GO
