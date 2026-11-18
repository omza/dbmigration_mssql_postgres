-- Object: mart_technische_doku.dqm_caigos_gas_hausanschluss
-- Type  : VIEW




/*
	select * from [mart_technische_doku].[dqm_caigos_gas_hausanschluss] order by strasse, hausnummer, hausnummer_zusatz, ort

*/



CREATE view [mart_technische_doku].[dqm_caigos_gas_hausanschluss] as


	with geraetearten as (

		select 
			cast([wert] as int) as id_geraeteart
			,[definition] as geraeteart
		from 
			[core].[schluesseldefinition]
		where
			feldname = 'id_geraeteart'

	), 

	hak_protokoll as (

		select
			METERRING_CODE
			,cast(DATUM as date) as letzte_kontrolle_protokoll
			,[DATEIBEZEICHNUNG_CSV] as protokoll_ablage
			,[DATEIBEZEICHNUNG_PDF] as protokoll
			,row_number() over (partition by METERRING_CODE order by DATUM desc) as rang
		from
			raw.wilken_objhausanschlusskontrolle

	), 

	gas_zp_mit_geraet as (

		select
			zp.id_zp,
			zp.meteringcode,
			zp.abnahmestelle_adresse,
			zp.ablesetour_nr,
			--zp.wilken_brw_nr,
			lzg.id_geraet,
			lzg.einbaudatum as einbaudatum_geraet,
			lzg.ausbaudatum as ausbaudatum_geraet,
			zp.abnahmestelle_straße,
			zp.abnahmestelle_hausnummer,
			zp.abnahmestelle_hausnummer_zusatz,
			zp.abnahmestelle_plz,
			zp.abnahmestelle_ort,

			ROW_NUMBER() over (partition by zp.id_zp order by lzg.einbaudatum desc ) as sequence_geraete
		from
			core.zaehlpunkte zp

		join
			core.link_zaehlpunkt_geraet lzg 
		on 
			zp.id_zp = lzg.id_zp 
			and zp.id_mandant = lzg.id_mandant
			and zp.id_energieart = lzg.id_energieart
			--and getdate() between lzg.einbaudatum and lzg.ausbaudatum
		where
			zp.id_mandant = 1
			and zp.id_energieart = 2


	),

	grundliste as (

		select
			[mha_id]
			,isnull([installationsdatum], [einbaudatum]) as herstellungsdatum
			,isnull(hak.letzte_kontrolle_protokoll,zp.einbaudatum_geraet) as  letzte_ha_kontrolle
			,case 
				when ausbaudatum_geraet = convert(date, '31.12.9999',104) 
				then convert(date,'31.12.' + cast(g.naechste_eichung as varchar),104) 
				else null
			end as ende_naechste_eichfrist
			--,case when ausbaudatum_geraet <> convert(date, '31.12.9999',104) then ausbaudatum_geraet else null end stillgelegt_am
			,[netzobjekt]
			,[netzobjekt_nr]
			,[status]
			,[schaden_vorhanden]
			,[druckstufe]
			,[druckebene]
			,[strasse]
			,[hausnummer]
			,[hausnummer_zusatz]
			--,[hausnummer_original]
			--,[hausnummer_zusatz_original]
			,[ort]
			,[wilken_csp_auftrag]
			,[bemerkung]
			,[bemerkung2]
			,[besonderheit]

			,[installationsdatum]
			,[einbaudatum]
			,[herstellungsjahr]
			,[meister_bezeichnung]
			,[meister_nr]
			,[tiefbau]
			,[tiefbau_nr]
			,[mauerdurchbruch]
			,[mha_userfld1]
			,[mha_userfld2]
			,[mha_userfld3]
			,[mha_userfld4]
			,[mha_userfld5]
			,[mha_userfld6]
			,[mha_userfld7]
			,[mha_userfld8]
			,[lageinfo]
			,[feldbuchnummer],
			--
			zp.id_zp,
			zp.meteringcode,
			zp.abnahmestelle_adresse,
			--zp.ablesetour_nr,
			--zp.wilken_brw_nr,
			zp.id_geraet,
			zp.einbaudatum_geraet,
			zp.ausbaudatum_geraet,
			--zp.sequence_geraete,
			g.geraetenummer,
			ga.geraeteart,
			gt.geraetetyp,
			gst.standardgeraetetyp,
			g.baujahr,
			g.eichung,
			g.naechste_eichung,
			hak.letzte_kontrolle_protokoll,
			hak.protokoll,
			hak.protokoll_ablage
		from
			stage.caigos_gas_hausanschluesse ha

		left join
			gas_zp_mit_geraet zp
		on
			REPLACE(UPPER(zp.abnahmestelle_straße),' ','') = REPLACE(UPPER(ha.strasse),' ','')
			and zp.abnahmestelle_hausnummer = try_cast(ha.hausnummer as int)
			and UPPER(ISNULL(zp.abnahmestelle_hausnummer_zusatz,'')) = UPPER(ha.hausnummer_zusatz)
			and UPPER(LTRIM(RTRIM(zp.abnahmestelle_ort))) = UPPER(LTRIM(RTRIM(ha.ort)))
			and zp.sequence_geraete = 1

		left join
			core.geraete g
		on
			zp.id_geraet = g.id_geraet

		left join
			geraetearten ga on g.id_geraeteart = ga.id_geraeteart

		left join
			core.geraetetypen gt on g.id_geraetetyp = gt.id_geraetetyp

		left join
			core.geraetetypen_standard gst on g.id_standardgeraetetyp = gst.id_standardgeraetetyp

		left join
			hak_protokoll hak on hak.METERRING_CODE = zp.meteringcode and hak.rang = 1 

		where
			mha_id not in ('{00000000-0000-0000-0000-000000000000}')
			--and isnull(ha.strasse,'') <> ''
			--and isnull(ha.hausnummer,'') <> ''
	), 
	
	aggregiert as (

		select
			[mha_id]
			,herstellungsdatum
			,max(letzte_ha_kontrolle) as letzte_ha_kontrolle
			,min(ende_naechste_eichfrist) as ende_naechste_eichfrist
			,case when max(ausbaudatum_geraet) <> convert(date,'31.12.9999',104) then max(ausbaudatum_geraet) else null end as stillgelegt_am
			,count(id_zp) as anzahl_abnahmestellen
			,[netzobjekt]
			,[netzobjekt_nr]
			,[status]
			,[schaden_vorhanden]
			,[druckstufe]
			,[druckebene]
			,[strasse]
			,[hausnummer]
			,cast([hausnummer_zusatz] as varchar(20)) as [hausnummer_zusatz]
 			--,[hausnummer_original]
			--,[hausnummer_zusatz_original]
			,[ort]
			,[wilken_csp_auftrag]
			,[bemerkung]
			,[bemerkung2]
			,[besonderheit]

			,[installationsdatum]
			,[einbaudatum]
			,[herstellungsjahr]
			,[meister_bezeichnung]
			,[meister_nr]
			,[tiefbau]
			,[tiefbau_nr]
			,[mauerdurchbruch]
			,[mha_userfld1]
			,[mha_userfld2]
			,[mha_userfld3]
			,[mha_userfld4]
			,[mha_userfld5]
			,[mha_userfld6]
			,[mha_userfld7]
			,[mha_userfld8]
			,[lageinfo]
			,[feldbuchnummer]

		from
			grundliste
		group by
			[mha_id]
			,herstellungsdatum
			,[netzobjekt]
			,[netzobjekt_nr]
			,[status]
			,[schaden_vorhanden]
			,[druckstufe]
			,[druckebene]
			,[strasse]
			,[hausnummer]
			,[hausnummer_zusatz]
			--,[hausnummer_original]
			--,[hausnummer_zusatz_original]
			,[ort]
			,[wilken_csp_auftrag]
			,[bemerkung]
			,[bemerkung2]
			,[besonderheit]

			,[installationsdatum]
			,[einbaudatum]
			,[herstellungsjahr]
			,[meister_bezeichnung]
			,[meister_nr]
			,[tiefbau]
			,[tiefbau_nr]
			,[mauerdurchbruch]
			,[mha_userfld1]
			,[mha_userfld2]
			,[mha_userfld3]
			,[mha_userfld4]
			,[mha_userfld5]
			,[mha_userfld6]
			,[mha_userfld7]
			,[mha_userfld8]
			,[lageinfo]
			,[feldbuchnummer]
	)
	-- fehlerbilder
	select
		case 
			when stillgelegt_am is not null then 'Stillgelegung prüfen (letzte Abnahmestelle in Wilken vertragslos)' 
			else 'Adressbestandteil im Caigos nicht gepflegt'
		end as fehlerbild
		,*
	from
		aggregiert
	where
		stillgelegt_am is not null
		or Isnull([strasse],'') = ''
		or Isnull([hausnummer],'') = ''
		or hausnummer = '0'
		or Isnull([ort],'') = ''

			


GO
