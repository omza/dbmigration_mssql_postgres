-- Object: mart_netzvertrieb.wilken_ressourcen_steuerbox
-- Type  : VIEW



/*

	Für den IMsys und Steuerboxen Rollout braucht Martin eine Aufstellung aller Abnahmestellen in einem Netzgebiet (NVP = Netzverknüpfungspunkt)
	mit der Technischen Ressource sowie den Steuerboxen und Daten aus Wilken ESM

	Netzverknüpfungspunkt [NVP ERP]	Wilken Energy ESM  OK
	NeLo	Wilken Energy OK
	MeLo	Wilken Energy OK
	MaLo	Wilken Energy OK 
	Installierte Leistung (kW)	ESM / Technische Ressource OK
	Inbetriebnahmedatum	ESM /Technische Ressource OK
	Zählernummer	Wilken Energy OK
	Smart Meter Gateway	Wilken Energy OK
	--Steuerbox	V2.0
	Lastganggemesssen	Wilken Energy OK
	MaStRNr (SEE)	Wilken Energy OK
	MaStRNr.-Anlage	Wilken Energy OK
	-- SR-ID	V2.0
	Technische Ressource (ID)	Wilken Energy OK
	Netzverknüpfungspunkt [NVP GIS]	Caigos

	-- change log
	08.09.2026	OMe	initial
	11.09.2026	OMe	weitere Infos hinzu
	23.09.2026	OMe	technische Ressourcen und ESM dazu

	-- Test 
	select * from [mart_netzvertrieb].[wilken_ressourcen_steuerbox] order by melo
	
*/


CREATE view [mart_netzvertrieb].[wilken_ressourcen_steuerbox] as

	
	with geraeteart as ( 
		
		select
			cast(wert as int) as id_geraeteart,
			definition as geraeteart
		from
			core.schluesseldefinition
		where
			feldname = 'id_geraeteart'

	), 

	gateway as (

		select
			bez.beziehungsart
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

		--left join
		--	raw.wilken_enzenr zenr   on z.ZENR_NR = zenr.ZENR_NR and z.MND_ID = zenr.MND_ID
		--left join
		--	raw.wilken_enzaehlerlos los on z.quellsystem_ident = los.ZAE_ID and z.id_mandant = los.MND_ID
		
		where
			lzpg.id_status = 1
			and lzpg.id_energieart = 1
			and getdate() between lzpg.einbaudatum and lzpg.ausbaudatum
	),

	nelos as (

		select distinct
			id_zp
			,id_mandant
			,netzlokation
			,melofunktion
		from
			core.lokationsbuendel lb
		where
			lb.id_lokationsbuendel_status = 1
			and getdate() between lb.gueltig_ab and lb.gueltig_bis
			and netzlokation is not null

	),

	technische_ressourcen_esm as (

		select distinct
			tr.id_mandant,
			tr.id_ressource,
			tr.id_zp,
			tr.id_abn,
			ressourcen_nummer,
			ressource_nutzungsart,
			ressource_bemerkung,
			nennleistung_kw_abgabe,
			nennleistung_kw_aufnahme,
			ressource_gueltig_ab,
			malo.malo,

			eanl.einspeiseanlage,
			eanl.energietraeger,
			eanl.id_status,
			eanl.installierte_leistung,
			eanl.bnetza_eeg_schluessel,
			eanl.marktstammdatenregister_nummer,
			eanl.netzverknuepfungspunkt,
			eanl.inbetriebnahme,
			eanl.stromerzeugungseinheit_mastnr_nummer
		from
			core.technische_ressourcen tr

		left join
			core.einspeiseanlagen eanl 
		on 	
			tr.id_ressource = eanl.id_ressource
			and tr.id_mandant = eanl.id_mandant

		left join
			core.marktlokationen malo 
		on 
			case when ressource_nutzungsart = 'Erzeugung' then id_malo_einspeisung else id_malo_bezug end = malo.id_malo 
			and tr.id_mandant = malo.id_mandant and malo.active = 1

	),

	wilken_nvp as (

		select distinct
			id_zp,
			id_mandant,
			netzverknuepfungspunkt
		from
			technische_ressourcen_esm
		where
			netzverknuepfungspunkt is not null
			and id_zp is not null
	)

	select distinct

		nvp.netzverknuepfungspunkt,
		nvp_sgop.Netzgebiet as netzgebiet_sgop,
		eha.nvp_trommelnr as caigos_trommelnr,

		nelo.netzlokation,

		--zp.id_zp,
		zp.meteringcode as melo,
		--nelo.melofunktion,

		isnull(malo.malo, tr.malo) as malo,
		--er.energierichtung,

		-- technische ressource
		isnull(tr.installierte_leistung,isnull(tr.nennleistung_kw_abgabe, tr.nennleistung_kw_aufnahme)) as installierte_leistung,
		isnull(tr.inbetriebnahme,tr.ressource_gueltig_ab) as inbetriebnahme,
		tr.ressourcen_nummer as [tr_id],
		tr.ressource_nutzungsart, 
		case
			when tr.ressource_bemerkung is null then tr.energietraeger	
			else tr.ressource_bemerkung + case 
											when tr.energietraeger is null then ''
											else ' (' + tr.energietraeger + ')'
										  end
		end tr_bemerkung,
		--

		mbt.messstellenbetreiber,
		mbt.eigener_messstellenbetreiber,

		--
		sp.spannungsebene,
		zv.zaehlverfahren,
		zae.zaehlernummer,
		--zae.einbaudatum,
		zae.geraetetyp,
		--zae.nenngroesse,
		--zae.standardgeraetetyp,

		r.gateway,
		r.gateway_geraetetyp,

		-- technische Ressourcen
		tr.bnetza_eeg_schluessel,
		tr.marktstammdatenregister_nummer,
		tr.stromerzeugungseinheit_mastnr_nummer



	from

		core.link_kunde_zaehlpunkt lkz

	join
		core.zaehlpunkte zp on lkz.id_zp = zp.id_zp and lkz.id_mandant = zp.id_mandant

	join
		core.spannungsebenen sp 
	on 
		zp.id_spannungsebene = sp.id_spannungsebene
		and zp.id_mandant = sp.id_mandant
		and zp.id_energieart = sp.id_energieart

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
		gateway r on zae.id_geraet = r.zaehler and r.rang = 1

	left join
		[core].[zaehlverfahren] zv on zp.id_zaehlverfahren = zv.id_zaehlverfahren and zp.id_mandant = zv.id_mandant and zp.id_energieart = zv.id_energieart


	left join
		core.messstellenbetreiber mbt 
	on 
		zp.id_messstellenbetreiber = mbt.id_messstellenbetreiber
		and lkz.id_mandant = mbt.id_mandant
		and zp.id_energieart = mbt.id_energieart

	left join
		nelos nelo
	on
		lkz.id_mandant = nelo.id_mandant
		and zp.id_zp = nelo.id_zp

	left join
		technische_ressourcen_esm tr
	on
		lkz.id_mandant = tr.id_mandant
		and zp.id_zp = tr.id_zp

	left join
		wilken_nvp nvp
	on
		lkz.id_mandant = nvp.id_mandant
		and zp.id_zp = nvp.id_zp

	left join
		[raw].[sgop_netzgebiete_abnahmestellen] nvp_sgop on zp.id_abn = nvp_sgop.id_abn 

	left join
		stage.caigos_elektro_hausanschluesse eha
	on
		nelo.netzlokation = eha.netzlokation

	where
		lkz.active = 1 
		and lkz.id_mandant = 1
		and lkz.id_vertragsart in (1,2) -- kein MSB Vertrag (Wie am 19.08.25 mit Martin S. besprochen)
		and zp.id_energieart = 1 --Strom
		and zp.id_zp_typ = 1 -- nur physikalische Zählpunkte
		and n.eigenes_netz = 1

	



GO
