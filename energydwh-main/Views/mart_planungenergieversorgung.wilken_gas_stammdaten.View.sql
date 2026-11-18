-- Object: mart_planungenergieversorgung.wilken_gas_stammdaten
-- Type  : VIEW




/*

	Daniel Lescow braucht technische infos zur weiterverarbeitung in seinen Digitalisierungsprozessen
	Nur Gas Abnahmestellen im eigenen Netzgebiet

	-- change log

	03.09.2026 Änderung SLP Zuordnung auf Wunsch Alexander Hecht	

	-- Test 

		select top 10 * from [mart_planungenergieversorgung].[wilken_gas_stammdaten] 
		

*/


CREATE view [mart_planungenergieversorgung].[wilken_gas_stammdaten] as

	
	with lagerstatus as ( 
		
		select
			wert as id_lagerstatus,
			definition as lagerstatus
		from
			core.schluesseldefinition
		where
			feldname = 'zae_lagerstatus'

	),
	geraeteart as ( 
		
		select
			cast(wert as int) as id_geraeteart,
			definition as geraeteart
		from
			core.schluesseldefinition
		where
			feldname = 'id_geraeteart'

	), 

	regler as (

		select
			bez.beziehungsart
			,bez.slave_id_geraet as zaehler
			--,bez.master_quellsystem_ident
			,r.geraetenummer as regler
			,bez.master_einbaudatum as regler_einbau
			,r.quellsystem_ident as ID_ZAE
			,r.gasdruck as gasdruck_regler,

			-- neue felder
			r.baujahr as regler_baujahr,
			cast(r.eichung as varchar) as regler_eichung,
			cast(r.naechste_eichung as varchar) as regler_naechste_eichung,
			lager.lagerstatus as regler_lagerstatus,
			ztp.geraetetyp as regler_geraetetyp,
			sztp.standardgeraetetyp as regler_standardgeraetetyp

			--,bez.*
		from
			core.link_geraetebeziehungen bez	

		left join
			core.geraete r on bez.master_id_geraet = r.id_geraet and r.id_quellsystem = 1

		left join
			core.geraetetypen ztp on r.id_geraetetyp = ztp.id_geraetetyp and bez.master_id_mandant = ztp.id_mandant 

		left join
			core.geraetetypen_standard sztp on r.id_standardgeraetetyp = sztp.id_standardgeraetetyp and bez.master_id_mandant = sztp.id_mandant

		left join
			lagerstatus lager on r.id_lagerstatus = lager.id_lagerstatus

		where
			id_status_geraetebeziehung <> 9 -- keine stornierten
			and id_beziehnungsart = 190770450 -- Gasregler beziehung
			and bez.slave_id_geraet is not null
			and getdate() between master_einbaudatum and bez.master_ausbaudatum
			and getdate() between bez.gueltig_von and bez.gueltig_bis
	
	),
	geraete as (

		select distinct
			lzpg.id_zp,
			lzpg.id_mandant,
			z.id_geraet,
			z.quellsystem_ident id_zaehler,
			lzpg.id_status,
			lzpg.einbaudatum,
			lzpg.ausbaudatum,
			z.geraetenummer as zaehlernummer,
			lzpg.id_link_zp_geraet,
			z.id_energieart,
			z.baujahr,
			z.eichung,
			z.naechste_eichung,
			
			z.los_nummer,
			case 
				when ISNULL(z.id_losstatus,0) = 0 then 'Zähler hat noch nie an einem Losverfahren teilgenommen'
				when z.id_losstatus = 1 then 'Zähler gehört zu einem Los'
				when z.id_losstatus = 2 then 'Zähler ist aus dem Los herausgefallen'
				else 'unbekannt'
			end los_status,
			lager.lagerstatus,
			ztp.geraetetyp,
			sztp.standardgeraetetyp,
			--zenr.ZENR_BEZEICHNUNG zaehler_energierichtungen,
			ztp.nenngroesse,
			z.zaehlerpin


		from
			core.link_zaehlpunkt_geraet lzpg
		left join
			core.geraete z on lzpg.id_geraet = z.id_geraet and lzpg.id_mandant = z.id_mandant
		left join
			core.geraetetypen ztp on z.id_geraetetyp = ztp.id_geraetetyp and lzpg.id_mandant = ztp.id_mandant and ztp.id_quellsystem = 1 -- wilken
		left join
			core.geraetetypen_standard sztp on z.id_standardgeraetetyp = sztp.id_standardgeraetetyp and z.id_mandant = sztp.id_mandant
		left join
			lagerstatus lager on z.id_lagerstatus = lager.id_lagerstatus
		--left join
		--	raw.wilken_enzenr zenr   on z.ZENR_NR = zenr.ZENR_NR and z.MND_ID = zenr.MND_ID
		--left join
		--	raw.wilken_enzaehlerlos los on z.quellsystem_ident = los.ZAE_ID and z.id_mandant = los.MND_ID
		
		where
			lzpg.id_status = 1
			and lzpg.id_energieart = 2
			and getdate() between lzpg.einbaudatum and lzpg.ausbaudatum
	)
	select
		k.kunden_nummer,
		ea.energieart,
		lkz.vertragsart,
		zp.meteringcode as melo,
		malo.malo,
		er.energierichtung,
		n.netz,
		sp.spannungsebene,
		zp.gasdruck_mbar,
		--
		zv.zaehlverfahren,
		lp.lastprofil,
		--lp.lastprofil_nummer,
		--
		zp.abnahmestelle_straße,
		zp.abnahmestelle_hausnummer,
		zp.abnahmestelle_hausnummer_zusatz,
		zp.abnahmestelle_plz,
		zp.abnahmestelle_ort,
		zp.ablesetour_nr,
		lto.ablesetour,
		zae.zaehlernummer,
		zae.einbaudatum,
		zae.geraetetyp,
		zae.nenngroesse,
		zae.standardgeraetetyp,
		zae.baujahr,
		zae.eichung,
		zae.naechste_eichung,
		zae.los_nummer,
		zae.los_status,
		zae.lagerstatus,

		r.regler,
		r.regler_einbau,
		r.gasdruck_regler as regler_gasdruck,

		-- neue felder
		r.regler_baujahr,
		r.regler_eichung,
		r.regler_naechste_eichung,
		r.regler_lagerstatus,
		r.regler_geraetetyp
		--r.regler_standardgeraetetyp ist immer leer

	from
		core.kunden k

	join
		core.link_kunde_zaehlpunkt lkz on k.id_kunde = lkz.id_kunde and k.id_mandant = lkz.id_mandant and lkz.active = 1

	join
		core.zaehlpunkte zp on lkz.id_zp = zp.id_zp and k.id_mandant = zp.id_mandant

	join
		core.netze n on zp.id_netz = n.id_netz

	join
		core.energiearten ea on zp.id_energieart = ea.id_energieart

	left join
		core.marktlokationen malo on zp.id_zp = malo.id_zp and zp.id_mandant = malo.id_mandant and malo.active = 1

	left join
		core.energierichtungen er on malo.id_energierichtung = er.id_energierichtung

	left join
		geraete zae on zp.id_zp = zae.id_zp and zp.id_mandant = zae.id_mandant and zp.id_energieart = zae.id_energieart

	left join
		core.ablesetouren lto on zp.ablesetour_nr =lto.id_ablesetour and zp.id_mandant = lto.id_mandant

	left join
		core.spannungsebenen sp on zp.id_spannungsebene = sp.id_spannungsebene and zp.id_mandant = sp.id_mandant and zp.id_energieart = sp.id_energieart


	left join 
		regler r on zae.id_geraet = r.zaehler

	left join
		[core].[lastprofile] lp on zp.id_lastprofil = lp.id_lastprofil and zp.id_mandant = lp.id_mandant and zp.id_energieart = lp.id_energieart

	left join
		[core].[zaehlverfahren] zv on zp.id_zaehlverfahren = zv.id_zaehlverfahren and zp.id_mandant = zv.id_mandant and zp.id_energieart = zv.id_energieart

	where
		k.active = 1
		and lkz.id_vertragsart <> 3 -- kein MSB Vertrag (Wie am 19.08.25 mit Martin S. besprochen)
		and zp.id_energieart = 2 --Gas
		and n.eigenes_netz = 1
	


GO
