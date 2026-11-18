-- Object: mart_energiemanagement.FACT_IPUEP_MESSPUNKTE_AVG_VERBRAUCH
-- Type  : VIEW



CREATE view [mart_energiemanagement].[FACT_IPUEP_MESSPUNKTE_AVG_VERBRAUCH] as


	with anschriften as (

		select
			mp.messpunkt_ident,
			ort.ORT,
			strasse.STRASSE
		from
			core.messpunkte mp
		cross apply 
			(select Item as ORT from Realdwh.dbo.SplitStrings(mp.location_beschreibung,';') where Number = 2) ort 
		cross apply 
			(select Item as STRASSE from Realdwh.dbo.SplitStrings(mp.location_beschreibung,';') where Number = 3) strasse 
		where
			id_geraeteart = 302

	), ipueps as (

		SELECT distinct
			mp.id_messpunkt,
			mp.messpunkt_ident,
			mp.messpunkt_name,
			mp.messpunkt_beschreibung,
			--mp.location_beschreibung,
			--ort.ORT,
			ipuep.E_NR_IPUEP,
			PROJEKT_NR,
			TANNISADRNR,
			PLZ,
			ISNULL(ipuep.ORT, adr.ORT) as ORT,	
			LTRIM(RTRIM(ISNULL(ipuep.STRASSE,ISNULL(adr.STRASSE,'')) + ' ' + ISNULL(HAUSNUMMER,'') + ' ' + ISNULL(HAUSNUMMERNZUSATZ,''))) as ANSCHRIFT
		FROM 
			[EnergyDWH].[core].[messpunkte] mp 
		left join
			raw.nedi_devices ndev on mp.messpunkt_ident = ndev.device 
		left join
			(select * from RealDWH.dwh.DIM_UEBERGABEPUNKT_IP where IP_ADRESSE_SWITCH <> '10.135.144.41') ipuep on mp.messpunkt_ident = ipuep.IP_ADRESSE_SWITCH
		left join
			anschriften adr on mp.messpunkt_ident = adr.messpunkt_ident 
		where 
			id_geraeteart = 302

	), tagesverbrauch as (

		select
			[id_messpunkt],
			YEAR(tag) jahr,
			MONTH(tag) monat,
			avg([tagesverbrauch_kWh]) avg_kwh,
			avg([Wert]) avg_wert,
			max([messeinheit]) as einheit,
			count(distinct tag) as tage
		from
			[core].[messwerte_tag]
		where
			id_energieart = 1
		group by
			[id_messpunkt],
			YEAR(tag),
			MONTH(tag)
	)



	select
		ipueps.*,
		tagesverbrauch.avg_kwh as avg_kWh_tag,
		tagesverbrauch.avg_wert,
		tagesverbrauch.einheit,
		tagesverbrauch.tage as anzahl_tage_im_zeitraum,
		jahr,
		monat
	from 
		ipueps
	left join
		tagesverbrauch on ipueps.id_messpunkt = tagesverbrauch.id_messpunkt




GO
