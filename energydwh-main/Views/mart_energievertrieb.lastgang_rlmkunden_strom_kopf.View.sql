-- Object: mart_energievertrieb.lastgang_rlmkunden_strom_kopf
-- Type  : VIEW




/*
	
	Kopfdaten für den Lastgangversand an Kunden durch Energievertrieb
	Ansprechpartner Nicola Lindhorst, Michelle Jaß und Sonja von Prossel



	-- Test 

		select * from [mart_energievertrieb].[lastgang_rlmkunden_strom_kopf] 
		where 
			meteringcode = 'DE0004732284401000000000000231196'--'DE0004732284401000000000000095190'
			and jahr = 2025
			and monat = 9
		

*/


CREATE view [mart_energievertrieb].[lastgang_rlmkunden_strom_kopf] as

	
	with kalender as ( 

		select 
			MONTH(tag) as monat
			,YEAR(tag) as jahr
			,convert(varchar(10),min(tag),104) + ' - ' + convert(varchar(10),max(tag),104) as zeitraum
			,count(*) as daten
		from
			core.kalender
		group by
			MONTH(tag)
			,YEAR(tag)		
	
	),

	messpunkt as (

		select 
			mp.id_messpunkt
			,mp.messpunkt_ident
			,mp.messpunkt_name
			,max(case when mpa.id_messpunkt_attribut = 3 then wert else null end) as wandlerfaktor
		from 
			core.messpunkte mp
		left join
			core.messpunkt_attribute mpa on mp.id_messpunkt = mpa.id_messpunkt 
		where
			id_quellsystem = 4
		group by
			mp.id_messpunkt
			,mp.messpunkt_ident
			,mp.messpunkt_name
	),
	lagerstatus as ( 
		
		select
			wert as id_lagerstatus,
			definition as lagerstatus
		from
			core.schluesseldefinition
		where
			feldname = 'zae_lagerstatus'

	),
	geraete as (

		select distinct
			lzpg.ZPT_ID id_zp,
			try_cast(lzpg.MND_ID as int) id_mandant,
			lzpg.ZAE_ID id_zaehler,
			lzpg.ZPG_STATUS,
			try_convert(date,lzpg.ZPG_EINBAUDATUM,120) einbaudatum,
			try_convert(date,lzpg.ZPG_AUSBAUDATUM,120) ausbaudatum,
			lzpg.ZPG_ZAE_NR zaehlernummer,
			lzpg.ZPG_ID,
			isnull(z.ZAE_ENERGIEART,1) as id_energieart,
			lager.lagerstatus,
			ztp.geraetetyp,
			sztp.standardgeraetetyp,
			ztp.nenngroesse,
			z.ZAE_PIN as zaehlerpin

		from
			raw.wilken_enzptgeraet lzpg
		left join
			raw.wilken_enzaehler z on lzpg.ZAE_ID = z.ZAE_ID and lzpg.MND_ID = z.MND_ID
		left join
			core.geraetetypen ztp on z.ZTP_NR = ztp.quellsystem_ident and lzpg.MND_ID = ztp.id_mandant and ztp.id_quellsystem = 1 -- wilken
		left join
			core.geraetetypen_standard sztp on z.SZTP_NR = sztp.wilken_sztp_nr and z.MND_ID = sztp.id_mandant
		left join
			lagerstatus lager on z.ZAE_LAGERSTATUS = lager.id_lagerstatus
		where
			lzpg.ZPG_STATUS = 1
			and isnull(lzpg.ZPG_AUSBAUDATUM,getdate()) <= getdate()
			--and lzpg.ZPG_ZAE_NR is not null	
	)
	select
		ea.energieart,
		k.kunden_nummer as kundennummer,
		k.geschaeftspartner_name as kunde,
		zp.meteringcode as meteringcode,
		malo.malo as marktlokation,
		isnull(zae.zaehlernummer, mp.messpunkt_name) as zaehlernummer,
		zae.einbaudatum,
		zae.geraetetyp,
		zae.nenngroesse,
		zae.standardgeraetetyp,
		zae.lagerstatus,
		fg.fallgruppe,

		cal.jahr,
		cal.monat,
		cal.zeitraum,
		cal.daten,

		mp.id_messpunkt,
		mp.wandlerfaktor

	from
		kalender cal,
		core.kunden k
	join
		core.link_kunde_zaehlpunkt lkz on k.id_kunde = lkz.id_kunde and k.id_mandant = lkz.id_mandant and lkz.id_status in (1,2)
	join
		core.zaehlpunkte zp on lkz.id_zp = zp.id_zp and k.id_mandant = zp.id_mandant
	join
		core.energiearten ea on zp.id_energieart = ea.id_energieart
	left join
		core.marktlokationen malo on zp.id_zp = malo.id_zp and zp.id_mandant = malo.id_mandant and malo.active = 1 and malo.id_energierichtung = 1 -- Lieferung
	left join
		core.energierichtungen er on malo.id_energierichtung = er.id_energierichtung
	left join
		geraete zae on zp.id_zp = zae.id_zp and zp.id_mandant = zae.id_mandant and zp.id_energieart = zae.id_energieart
	left join
		core.fallgruppen fg on zp.id_zp = fg.id_zp and malo.id_energierichtung = fg.id_energierichtung and fg.active = 1
	left join
		messpunkt mp on zp.meteringcode = mp.messpunkt_ident
	where
		k.active = 1
		and k.unbundling_art in ('Netz und Vertrieb','Vertrieb')
		and zp.id_energieart = 1 -- Strom

	


GO
