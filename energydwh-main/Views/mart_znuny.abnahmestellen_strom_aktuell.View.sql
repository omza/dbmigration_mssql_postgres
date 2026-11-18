-- Object: mart_znuny.abnahmestellen_strom_aktuell
-- Type  : VIEW


/*
	Für den Smartmeter Störungsprozess sollen Kunden und Messlokationsdaten aus Energy DWH mit folgenden Wilken Daten für OTRS bereitgestellt werden

	Kunde
	-----
	kundennummer
	person_vorname
	person_name
	strasse
	hausnummer
	hausnummer_zusatz
	plz
	ort
	telefonnummer
	mobilnummer
	email
	vertrag_nummer
	produkt

	Technik
	-------
	geraetetyp
	standardgeraetetyp
	nenngroesse
	eichung
	naechste_eichung
	zaehlerpin
	fallgruppe

	Master / iMSys
	--------------
	Master (meteringcode)
	malo
	zaehlernummer
	master_geraet
	master_einbaudatum

	-- change log
	28.09.2026	OMe	Renovierung der Gatewayinformationen


	-- doubletten
	select a.* from mart_znuny.abnahmestellen_strom_aktuell a
	join
		(select  melo,malo,kunden_nummer, zaehlernummer from mart_znuny.abnahmestellen_strom_aktuell group by melo,malo,kunden_nummer,zaehlernummer having count(*) > 1) db 
	on
		a.melo = db.melo
		and a.malo = db.malo
		and a.kunden_nummer = db.kunden_nummer
		and a.zaehlernummer = db.zaehlernummer
	order by 
		a.melo, 
		a.malo

	--test
	select * from [mart_znuny].[abnahmestellen_strom_aktuell] where gateway is not null and melo = 'DE0004732284401000000000000058380'

*/
CREATE view [mart_znuny].[abnahmestellen_strom_aktuell]
as

	with malo as (

		select distinct
			[id_mandant]
			,[id_zp]
			,[id_energierichtung]
			,[malo]
			,row_number() over (partition by id_zp, id_energierichtung order by [valid_from] desc) as rang
		from
			core.marktlokationen
	), 

	gateways as (


		select
			bez.beziehungsart
			--,bez.slave_quellsystem_ident as id_link_zp_geraet
			,bez.slave_id_geraet as zaehler
			--,bez.master_quellsystem_ident
			,r.geraetenummer as gateway
			,bez.master_einbaudatum as gateway_einbau
			,r.quellsystem_ident as ID_ZAE

			-- neue felder
			,r.baujahr as gateway_baujahr,
			cast(r.eichung as varchar) as gateway_eichung,
			cast(r.naechste_eichung as varchar) as gateway_naechste_eichung,
			ztp.geraetetyp as gateway_geraetetyp,
			sztp.standardgeraetetyp as gateway_standardgeraetetyp,

			row_number() over (partition by bez.slave_id_geraet, isnull(r.geraetenummer,'-') order by bez.master_einbaudatum desc) as rang
			
		from
			core.link_geraetebeziehungen bez	

		left join
			core.geraete r on bez.master_id_geraet = r.id_geraet and r.id_quellsystem = 1

		left join
			core.geraetetypen ztp on r.id_geraetetyp = ztp.id_geraetetyp and bez.master_id_mandant = ztp.id_mandant 

		left join
			core.geraetetypen_standard sztp on r.id_standardgeraetetyp = sztp.id_standardgeraetetyp and bez.master_id_mandant = sztp.id_mandant


		where
			id_status_geraetebeziehung <> 9 -- keine stornierten
			and id_beziehnungsart = 128248572	--Gateway -> Zähler 
			and bez.slave_id_geraet is not null
			and r.geraetenummer is not null
			and getdate() between master_einbaudatum and bez.master_ausbaudatum
			and getdate() between bez.gueltig_von and bez.gueltig_bis
	
	)

	select distinct

		zp.meteringcode as melo
		,isnull(malo.malo, -1) as malo
		,case when isnull(malo.id_energierichtung,1) = 2 then 1 else 0 end as einspeiser

		,zp.abnahmestelle_straße as strasse
		,zp.abnahmestelle_hausnummer as hausnummer
		,zp.abnahmestelle_hausnummer_zusatz as hausnummer_zusatz
		,zp.abnahmestelle_plz as plz
		,zp.abnahmestelle_ort as ort

		--,n.netz
		--,n.eigenes_netz
	
		--,lkz.*
		,fg.fallgruppe 

		,k.kunden_nummer
		,k.person_vorname
		,k.person_name
		,k.telefonnummer
		,k.mobilnummer
		,k.email

		,v.vertragsnummer
		,p.produkt
		,p.variante

		,g.geraetenummer as zaehlernummer
		,gt.geraetetyp
		,gts.standardgeraetetyp
		,gt.nenngroesse
		,g.eichung
		,g.naechste_eichung
		,g.zaehlerpin

		--
		,gw.beziehungsart
		,gw.gateway
		,gw.gateway_einbau


	from
		core.zaehlpunkte zp

	left join
		malo on zp.id_mandant = malo.id_mandant and zp.id_zp = malo.id_zp and malo.rang = 1 

	left join
		core.fallgruppen fg on fg.id_zp = zp.id_zp and isnull(malo.id_energierichtung,1) = fg.id_energierichtung and fg.active = 1

	join
		core.netze n on n.id_mandant = zp.id_mandant and n.id_energieart = zp.id_energieart and n.id_netz = zp.id_netz

	join
		core.link_kunde_zaehlpunkt lkz on zp.id_mandant = lkz.id_mandant and zp.id_zp = lkz.id_zp

	join
		core.kunden k on zp.id_mandant = k.id_mandant and lkz.id_kunde = k.id_kunde

	left join
		core.vertraege v 
	on
		zp.id_mandant = v.id_mandant 
		and zp.id_energieart = v.id_energieart 
		and lkz.id_vertrag = v.id_vertrag
		and getdate() between v.vertragsbeginn and v.vertragsende

	left join
		core.produkte p on v.id_produkt = p.id_produkt and v.id_produktvariante = p.id_produktvariante and zp.id_energieart = p.id_energieart

	join
		core.link_zaehlpunkt_geraet lzg 
	on 
		lzg.id_mandant = zp.id_mandant
		and lzg.id_energieart = zp.id_energieart
		and lzg.id_zp = zp.id_zp
		and getdate() between lzg.einbaudatum and lzg.ausbaudatum
		and lzg.id_status <> 9

	join
		core.geraete g
	on
		g.id_mandant = lzg.id_mandant
		and g.id_energieart = lzg.id_energieart
		and g.id_geraet = lzg.id_geraet

	left join
		core.geraetetypen gt  
	on
		g.id_mandant = gt.id_mandant
		and g.id_energieart = gt.id_energieart
		and g.id_geraetetyp = gt.id_geraetetyp

	left join
		core.geraetetypen_standard gts
	on
		g.id_mandant = gts.id_mandant
		and g.id_energieart = gts.id_energieart
		and g.id_standardgeraetetyp = gts.id_standardgeraetetyp

	-- gateways

	left join
		gateways gw --on lzg.id_link_zp_geraet = gw.id_link_zp_geraet
		 on g.id_geraet = gw.zaehler and gw.rang = 1

	where 
		zp.id_mandant = 1 --swnor
		and zp.id_energieart = 1 --strom
		and getdate() between lkz.valid_from and lkz.valid_to
		and lkz.id_vertragsart not in (3,5)
		and getdate() between k.valid_from and k.valid_to
		and n.eigenes_netz = 1
		and isnull(p.produkt_nummer,-1) <> '19900'


GO
