-- Object: mart_netzvertrieb.wilken_stammdaten
-- Type  : VIEW










/*

Martin Schäning braucht eine DB View aus Energy DWH mit folgenden Wilken Daten: 
	KISKundendaten GP-Adresse
		Anrede [Herr]
		Vorname
		Name
		Adresse
		Hausnummer
		Hausunternummer
		Telefon
		Handy
		E-Mail

	OK
 

	KISZaehlpunkt - KAAbnahmestelleUebersicht Abnahmestelle
		Metering Code
		MaLo
		MeLo
		Medium:
		Stromzähler (aktiv) [1001 - KAAbnahmestelleUebersicht Abnahmestelle Verbrauchsart]
		Gaszähler (aktiv) [2001]
		Wasserzähler (aktiv) [3001]
 
	OK


	Geräteakte TEC
		Verbundene Geräte und Gerätebeziehung(ein DB Feld?!) [05CCA0E500150C oder EPPC0210592669] OK
		Baujahr OK
		Eichung OK 
		Nächstes Eichung OK
		Losnummer OK
		Gerätetyp [Drehstromzähler Eintarif elektronisch DZG       DWSE20.266] OK
		Nenngröße [05/100(A)] OK
		Verbrauchsfallgruppe - [< 3000 bis 6000 kWh] OK



	Besprochene Änderungen /Hinzu

		Geschäftspartnernummer nicht interessant OK
		MeLO ist ZP nicht Malo Einspeiserichtung 2 OK
		Name der Tour ?
		Geräteakte -> Absprung aus KIC
			Losnummer Eichung etc OK
			Zählerpin OK
			Gerätetyp und Bezeichnung OK
		Nenngröße 05/100A OK
		Energierichtung: Ein/Zweirichtungszähler OK
		Die Verbrauchsfallgruppe OK

	Offen:

		Losnummer,					OK
		Name der Ablesetour,
		Zaehlerpin,                OK
		Ein/Zweirichtungszaehler ? OK


	19.08.2025
	1. Eichung nur Jahr
	2.	Ist eine zusätzliche Spalte für Smart Meter Gateways (SMGW) noch möglich anzubinden? => Oder generell Geräteverbindungen. 
	a.	Interessant wäre es eine weitere Spalte mit Daten des Smart Meter Gateways zu erhalten. => Abnahmestellenakte > 
	i.	Wir betreiben Messsysteme, die aus einem Stromzähler und einem Gateway bestehen. Die Smart Meter Gateway (SMGW) Nummer wäre hier auch interessant. Kommst du an diese Daten heran? Sie sehen ungefähr so aus: „EEMH0015977719“ oder „EPPCxxx“

	20.08.2025
	1.	Zum ersten Punkt: Ja gerne auch die Monate für die nächste Eichung entfernen. Das brauchen wir nicht so genau. 
	2.	Gerätebeziehung, bei moderne Messeinrichtung (mME) handelt es sich nur um einen digitalen Stromzähler ohne eine Kommunikation. Die Kommunikation erfolgt erst ab einem intelligenten Messsystem (iMSys) und hierfür brauchen wir die Schnittstelle bzw. das Smart Meter Gateway.
	3.	Wenn mehr als eine Gerätebeziehung vorliegt, dann würde ich es auch gerne wissen wollen, da dies auch ein Fehler (Datenleichen) sein können, welches systembedingt entstanden ist oder wenn später sog. Steuerboxen eingebaut werden. 
	a.	Schön wäre in dem Kontext auch das Datum, ab wann das SMGW gültig ist. (sozusagen das EInbaudatum) Das ist für die BNetzA jetzt wichtig geworden. ☹ Anforderungen über Anforderungen….
	4.	Kannst du noch eine Spalte über das Produkt aufbauen? Das wird für den Störungsprozess wichtig, da wir dann eine PRIO aufbauen können, da wir monatliche Produkt-Abrechnungen haben (FairWatt, Gezeiten, TuWatt….)



	-- Test 

		select top 200 * from [mart_netzvertrieb].[wilken_stammdaten] where malo is not null order by geschaeftspartner_name, energieart
		

*/


CREATE view [mart_netzvertrieb].[wilken_stammdaten] as

	
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
			z.ZAE_ENERGIEART as id_energieart,
			z.ZAE_BAUJAHR as baujahr,
			cast(z.ZAE_EICHJAHR as varchar) as eichung,
			cast(z.ZAE_NAECHSTESEICHJAHR as varchar) as naechste_eichung,
			los.LOS_NR + '(' + cast(los.LOS_NR_ZUSATZ as varchar) + ')' as los_nummer,
			case 
				when ISNULL(z.ZAE_LOSSTATUS,0) = 0 then 'Zähler hat noch nie an einem Losverfahren teilgenommen'
				when z.ZAE_LOSSTATUS = 1 then 'Zähler gehört zu einem Los'
				when z.ZAE_LOSSTATUS = 2 then 'Zähler ist aus dem Los herausgefallen'
				else 'unbekannt'
			end los_status,
			lager.lagerstatus,
			ztp.geraetetyp,
			sztp.standardgeraetetyp,
			zenr.ZENR_BEZEICHNUNG zaehler_energierichtungen,
			ztp.nenngroesse,
			z.ZAE_PIN as zaehlerpin,

			--
			gmaster.ZPG_ZAE_NR as master_geraet,
			gmaster.ZPG_GERAETEGRUNDTYP as master_id_geraeteart,
			master_art.geraeteart as master_geraeteart,
			try_convert(date,gbez.GBZ_GUELTIGAB,120) as master_beziehung_ab,
			try_convert(date,gmaster.ZPG_EINBAUDATUM,120) as master_einbaudatum,
			--
			gslave.ZPG_ZAE_NR as slave_geraet,
			gslave.ZPG_GERAETEGRUNDTYP as slave_id_geraeteart,
			slave_art.geraeteart as slave_geraeteart,
			try_convert(date,gbezslave.GBZ_GUELTIGAB,120) as slave_beziehung_ab,
			try_convert(date,gslave.ZPG_EINBAUDATUM,120) as slave_einbaudatum
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
		left join
			raw.wilken_enzenr zenr   on z.ZENR_NR = zenr.ZENR_NR and z.MND_ID = zenr.MND_ID
		left join
			raw.wilken_enzaehlerlos los on z.ZAE_ID = los.ZAE_ID and z.MND_ID = los.MND_ID
		left join
			raw.wilken_engeraetebeziehung gbez on lzpg.ZPG_ID = gbez.ZPG_ID_SLAVE and getdate() between gbez.[GBZ_GUELTIGAB] and isnull(gbez.[GBZ_GUELTIGBIS],getdate())
		left join
			raw.wilken_enzptgeraet gmaster on gbez.ZPG_ID_MASTER = gmaster.ZPG_ID
		left join
			raw.wilken_engeraetebeziehung gbezslave on lzpg.ZPG_ID = gbezslave.ZPG_ID_MASTER and getdate() between gbezslave.[GBZ_GUELTIGAB] and isnull(gbezslave.[GBZ_GUELTIGBIS],getdate())
		left join
			raw.wilken_enzptgeraet gslave on gbezslave.ZPG_ID_SLAVE = gslave.ZPG_ID
		left join
			geraeteart master_art on gmaster.ZPG_GERAETEGRUNDTYP = master_art.id_geraeteart
		left join
			geraeteart slave_art on gslave.ZPG_GERAETEGRUNDTYP = slave_art.id_geraeteart
		where
			lzpg.ZPG_STATUS = 1
			and isnull(lzpg.ZPG_AUSBAUDATUM,getdate()) <= getdate()
			and lzpg.ZPG_ZAE_NR is not null	
	),
	vertrag as (

		select
			l.GPVL_FKID as  [id_link_messeinheit]
			,v.GPVG_VERTRAGSNUMMER as vertrag_nummer
			,v.GPVG_ART as vertrag_art
			,v.GPVG_STATUS as vertrag_status
			,try_cast(v.GPVG_BEGINN as date) as vertrag_beginn 
			,try_cast(v.GPVG_ENDE as date) as vertrag_ende
			--
			,p.PRD_BEZEICHNUNG produkt
			--
			,try_cast(l.GPVL_GUELTIGAB as date) link_gueltig_ab
			,try_cast(l.GPVL_GUELTIGBIS as date) link_gueltig_bis
		from
			raw.wilken_crgpvertraglink l
		join
			raw.wilken_crgpvertrag v on l.GPVG_ID = v.GPVG_ID
		join
			raw.wilken_crprodukt p on v.PRD_ID = p.PRD_ID
		where
			l.GPVL_FKTYP = 0 -- link typ messeinheit
			and v.GPVG_STATUS = 1 -- aktiv

	)
	select
		k.kunden_nummer,
		k.geschaeftspartner_name,
		k.geschaeftspartner_name2,
		k.anrede,
		k.person_vorname,
		k.person_name,
		k.strasse,
		k.hausnummer,
		k.hausnummer_zusatz,
		k.plz,
		k.ort,
		k.telefonnummer,
		k.mobilnummer,
		k.email,
		ea.energieart,
		lkz.vertragsart,
		zp.meteringcode,
		malo.malo,
		er.energierichtung,
		zp.abnahmestelle_straße,
		zp.abnahmestelle_hausnummer,
		zp.abnahmestelle_hausnummer_zusatz,
		zp.abnahmestelle_plz,
		zp.abnahmestelle_ort,
		zp.ablesetour_nr,
		LTO_BEZEICHNUNG as ablesetour,
		zae.zaehlernummer,
		zae.einbaudatum,
		zae.geraetetyp,
		zae.nenngroesse,
		zae.standardgeraetetyp,
		zae.zaehler_energierichtungen,
		zae.baujahr,
		zae.eichung,
		zae.naechste_eichung,
		zae.los_nummer,
		zae.los_status,
		zae.lagerstatus,
		fg.fallgruppe,
		fg.ermittelt_am as fallgruppe_ermittelt_am,
		fg.fallgruppe_von,
		fg.fallgruppe_bis,
		zae.zaehlerpin,
			--
		zae.master_geraet,
		zae.master_geraeteart,
		zae.master_beziehung_ab,
		zae.master_einbaudatum,
			--
		zae.slave_geraet,
		zae.slave_geraeteart,
		zae.slave_beziehung_ab,
		zae.slave_einbaudatum,
			--
		v.vertrag_nummer,
		v.produkt,
		v.vertrag_beginn,
		v.vertrag_ende
		--
		--zae.ausbaudatum,
		--zae.ZPG_STATUS
	from
		core.kunden k
	join
		core.link_kunde_zaehlpunkt lkz on k.id_kunde = lkz.id_kunde and k.id_mandant = lkz.id_mandant and lkz.active = 1
	join
		core.zaehlpunkte zp on lkz.id_zp = zp.id_zp and k.id_mandant = zp.id_mandant
	join
		core.energiearten ea on zp.id_energieart = ea.id_energieart
	left join
		core.marktlokationen malo on zp.id_zp = malo.id_zp and zp.id_mandant = malo.id_mandant and malo.active = 1
	left join
		core.energierichtungen er on malo.id_energierichtung = er.id_energierichtung
	left join
		geraete zae on zp.id_zp = zae.id_zp and zp.id_mandant = zae.id_mandant and zp.id_energieart = zae.id_energieart
	left join
		core.fallgruppen fg on zp.id_zp = fg.id_zp and malo.id_energierichtung = fg.id_energierichtung and fg.active = 1
	left join
		raw.wilken_enlauftour lto on zp.ablesetour_nr =lto.LTO_NR and zp.id_mandant = lto.MND_ID
	left join
		vertrag v on lkz.id_link_messeinheit = v.id_link_messeinheit
	where
		k.active = 1
		and lkz.id_vertragsart <> 3 -- kein MSB Vertrag (Wie am 19.08.25 mit Martin S. besprochen)
	


GO
