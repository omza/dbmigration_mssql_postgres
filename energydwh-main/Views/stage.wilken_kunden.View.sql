-- Object: stage.wilken_kunden
-- Type  : VIEW



/*

	change log
	----------

	18.09.2026 Immer nur die letzte Zeitscheibe aus [raw].[wilken_g4bm_gspkmwadrvwnd] verwenden
	09.10.2026	Telefonnummer wird jetzt nicht mehr mit der Faxnummer gefüllt ;-) oh oh 


*/
CREATE view [stage].[wilken_kunden] as


	with partnerrollen as (
	
		select
			ro.ID as id_rolle,
			ro.[GSPARTNERID] as id_geschaeftspartner,
			[ROLLE],
			[NUMMER],
			gp.GSPNUMMER AS geschaeftspartner_nummer,
			cast(gp.MANDANT as int) as id_mandant,
			[KDNRENERGY],
			ro.STATUS as rollenstatus,
			gp.STATUS as partnerstatus



		from
			raw.wilken_g4bm_gsprolle ro with (nolock)
		join
			raw.wilken_g4bm_gspartner gp with (nolock) 
		on 
			ro.GSPARTNERID = gp.ID 
			and ro.KONZERN = gp.KONZERN
			and ro.MANDANT = gp.MANDANT
			--and ro.WERK = gp.WERK
		where
			isnull([KDNRENERGY],'X') <> 'INA'
			and ROLLE in ('D ','K ','DI','KI')			
			and isnull(gp.STATUS,'N') not in ('DIS','SAV','LOC')
	
	),
	verwendung as (

		-- Nur Verwendungstyp adressen aus Ivu Qlik App abgeleitet
		select
			cast(MANDANT as int) as id_mandant
			,[GSPARTNERID]
			,GPORIGINALID
			,[GPROLLEID]
			,[GSPANSCHRIFTID]
			,[GPPERSONID]
			,[GPPERSARTID]
			,[GPADRESSEID]
			,row_number() over (partition by [GPROLLEID] order by isnull(AENDERUNGSDATUM,ERSTELLUNGSDATUM) desc, isnull(AENDERUNGSUHRZEIT,ERSTELLUNGSUHRZEIT) desc) as rang

		from
			[raw].[wilken_g4bm_gspkmwadrvwnd] with (nolock)

		where
			TYP = 'ADR'
	),
	adressen as (

		select
			adr.ID
			,CASE 
				WHEN charindex('~~',adr.PONAME) > 0 THEN ltrim(rtrim(left(adr.PONAME,charindex('~~',adr.PONAME)-1)))
				ELSE adr.PONAME
			END	 as geschaeftspartner_name
			,CASE 
				WHEN charindex('~~',adr.PONAME) > 0 THEN ltrim(rtrim(right(adr.PONAME, len(adr.PONAME) - charindex('~~',adr.PONAME) -1)))
				ELSE NULL
			END	as geschaeftspartner_name2
			,LTRIM(RTRIM(adr.ZUSATZ)) as geschaeftspartner_zusatz
			,LTRIM(RTRIM(adr.STRASSE)) as strasse
			,CAST(adr.HAUSNRVON as VARCHAR) + CASE WHEN adr.HAUSNRBIS IS NOT NULL THEN '-' + CAST(adr.HAUSNRBIS as VARCHAR) ELSE '' END  as hausnummer
			,adr.HAUSNRVONZUS as hausnummer_zusatz
			,adr.LAND as laendercode
			,adr.PLZ as plz
			,adr.ORT as ort
			,adr.ORTSTEIL as ortsteil
			,adr.GEMEINDE as gemeindeschluessel
		from
			raw.wilken_g4bm_gspadresse adr with (nolock)

	)
	select distinct
		-- Energie_kunde
		kd.KND_ID as id_kunde
		,gp.id_mandant
		,kd.KND_NR1 as kunden_nummer	

		/*	kundenstatus

				0: Inaktiv
				1: Kunde aktiv
				2: Kunde bereit zur vorzeitigen
				Endabrechnung, z.B. wegen Auszug
				3: Angelegt in CSY, aber noch nicht
				in Energy bearbeitbar, wie Status 0:
				4: Kunde im Stornostatus
				7: Kunde zur Eog vorbereitet
				8: Leerstand
				9: Kunde gesperrt

		*/
		,Isnull(try_cast(kd.KND_STATUS as int),0) as id_kundenstatus

		/*	Unbundling Art
			Mögliche Werte: 
			0: Netz und Vertrieb
			1: Vertrieb
			2: Netz
			3: Messstellenbetrieb
		*/
		,case kd.knd_art_unbundling 
			when 0 then 'Netz und Vertrieb'
			when 1 then 'Vertrieb'
			when 2 then 'Netz'
			when 3 then 'Messstellenbetrieb'
			else 'unbekannt'
		end as unbundling_art		
		,try_cast(kd.KAT_NR as char(3)) as id_kundenkategorie
		,try_cast(kng.KNG_ID as int) as id_kundengruppe

		,try_cast(kd.KND_TURNUSRECHNUNG as int) as id_turnusrechnung

		,kd.knd_einzugdatum as einzugsdatum
		,kd.knd_auszugdatum as auszugsdatum
		
		--Geschäftspartner
		,gp.id_rolle
		,gp.rollenstatus

		,vw.[GSPARTNERID] as id_geschaeftspartner
		,gp.geschaeftspartner_nummer

		,gp.partnerstatus

		-- Namen
		,adr.geschaeftspartner_name
		,case
			when adr.geschaeftspartner_name2 <> adr.geschaeftspartner_zusatz
			then adr.geschaeftspartner_name2
			else NULL
		end as geschaeftspartner_name2
		,adr.geschaeftspartner_zusatz

		--ansprechpartner
		,vw.[GPPERSONID] as id_person
		,titel.BEZADRESSE as titel
		,anrede.BEZEICHNUNG as anrede
		,pers.VORNAME as person_vorname
		,pers.NAME as person_name
		,pers.NAMENSZUSATZ as person_zusatz 
		,CONVERT(date, pers.GEBDATUM, 23) as geburtsdatum
		,pers.GESCHLECHT as geschlecht
		,PERSONENTYP as person_typ

		-- anschrift
		,adr.strasse
		,adr.hausnummer
		,adr.hausnummer_zusatz
		,adr.laendercode
		,adr.plz
		,adr.ort
		,adr.ortsteil
		,adr.gemeindeschluessel

		-- Kontakte
		,kontakt.EMAIL as email
		,kontakt.TELEFONNUMMER as telefonnummer
		,kontakt.HANDY as mobilnummer
		,kontakt.TELEFAX as faxnummer

		--Zeitstempel
		,kd.[KND_ANGELEGT] as created_at
		,isnull(kd.KND_GEAENDERT,kd.KND_ANGELEGT) as changed_at

	FROM 
		partnerrollen gp
	join
		verwendung vw on gp.id_rolle = vw.GPROLLEID and gp.id_mandant = vw.id_mandant and vw.rang = 1
	join
		raw.wilken_enknd kd with (nolock) on 	gp.id_rolle = kd.RO_ID and gp.id_mandant = kd.MND_ID 
	join
		[raw].[wilken_g4bm_gspadrzeit] adrz with (nolock) on vw.GSPANSCHRIFTID = adrz.GSPANSCHRIFTID and adrz.GUELTIGBIS = '9999-12-31'
	join
		raw.wilken_g4bm_gspersart kontakt with (nolock) on vw.GPPERSARTID = kontakt.ID and kontakt.PERSONENART = 'GSP'
	join
		adressen adr on adrz.GSPADRESSEID = adr.ID 
	join
		raw.wilken_g4bm_gspperson pers with (nolock) on kontakt.GSPPERSONID = pers.ID
	left join
		raw.wilken_g4bm_anrede anrede with (nolock) on pers.ANREDEID = anrede.ID
	left join
		raw.wilken_g4bm_titel titel with (nolock) on pers.TITELID = titel.ID
	join
		raw.wilken_enkng kng with (nolock) on kd.KNG_ID = kng.KNG_ID and kd.MND_ID = kng.MND_ID
	join
		raw.wilken_enkategorie kat with (nolock) on kd.KAT_NR = kat.KAT_NR and kd.MND_ID = kat.MND_ID



GO
