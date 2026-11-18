-- Object: mart_systementwicklung.element_iot_zaehler_abnahmestellen_geo
-- Type  : VIEW







/*
	Anforderung von Christoph Mohr/ Jonas Hecht im Namen Systementwicklung und Planung. Alle Stromzähler aus elementiot mit Ihren Abnahmestellen aus Wilken Energy
	verknüpfen und zur Abnahmestelle eine Geolocation aus GoogleMaps Api 

	Change Log
	----------
	10.10.2025	Ome Umstellung auf core.messpunkte sowie core.messwerte 
	17.10.2025	OME	Wäremzähler hinzu
	22.10.2025	OMe	Wasserzähler dazu


	Test
	----
	select * from [mart_systementwicklung].element_iot_zaehler_abnahmestellen_geo  where energieart = 'Fernwärme'
	--where meteringcode in ('DE0004732285101000000000000231147', 'DE0004732285101000000000002230998','DE0004732284601000000000000051705','DE0004732284601000000000002231145')

*/
CREATE view [mart_systementwicklung].[element_iot_zaehler_abnahmestellen_geo] 
	as


	with monatskunden as (

		select distinct
			knd.id_kunde,
			knd.id_mandant,
			knd.kunden_nummer,
			knd.id_kundenstatus,
			knd.id_kundengruppe,
			knd.id_turnusrechnung,
			lkz.id_zp
		from 
			[core].[kunden] knd
		join
			core.link_kunde_zaehlpunkt lkz on knd.id_mandant = lkz.id_mandant and knd.id_kunde = lkz.id_kunde and lkz.active = 1

		where 
			knd.id_mandant = 1 
			and knd.id_kundengruppe = 1 
			and knd.id_kundenstatus in (1,2) 
			and knd.id_turnusrechnung = 3
	),
	
	element_stage as (

		select
			mp.id_energieart
			,mp.id_messpunkt
			,mp.messpunkt_name
			,case 
				when mp.id_energieart between 3 and 6 then mp.messpunkt_serialnummer
				else mp.messpunkt_name
			end as zaehlernummer
			,min(mp.created_at) as inserted_at
			,max(case when mpa.id_messpunkt_attribut = 6 then mpa.wert else null end) parser_id
			,try_cast(max(case when mpa.id_messpunkt_attribut = 8 then mpa.wert else null end) as decimal (5,0)) sf
			,try_cast(max(case when mpa.id_messpunkt_attribut = 9 then mpa.wert else null end) as decimal (5,1)) rssi
			,try_cast(max(case when mpa.id_messpunkt_attribut = 10 then mpa.wert else null end) as decimal (10,3)) snr
			,try_cast(max(case when mpa.id_messpunkt_attribut = 11 then mpa.wert else null end) as int) as  sende_interval_sec
		from
			core.messpunkte mp
		join
			core.messpunkt_attribute mpa on mp.id_messpunkt = mpa.id_messpunkt
		where
			mp.id_quellsystem = 2
		group by
			mp.id_messpunkt
			,mp.messpunkt_name
			,mp.id_energieart
			,mp.messpunkt_serialnummer

	),
	messwerte as (

		select 
			id_messpunkt
			,messung_am
			,messwert
			,id_obis
			,row_number() over (partition by id_messpunkt, id_obis order by messung_am desc) last_reading 
		from
			core.messwerte with (nolock)
		where
			id_obis in (11180,11280,50180, 30180,40180,60180)
	), 

	last_readings as (

		select
			id_messpunkt
			,max(messung_am) as last_reading_at
			,max(case when id_obis in (11180,50180) then messwert else null end) as zaehlerstand_bezug_kWh
			,max(case when id_obis = 11280 then messwert else null end) as zaehlerstand_einspeisung_kWh
			,max(case when id_obis in (30180,40180,60180) then messwert else null end) as zaehlerstand_wasser_m3
		from
			messwerte
		where
			last_reading = 1
		group by
			id_messpunkt
	),

	element as (
	
		select
			es.id_energieart,
			es.zaehlernummer,
			es.messpunkt_name as device_name,
			es.inserted_at,
			--es.parser_id,
			es.sende_interval_sec,
			es.sf,
			es.rssi as avg_rssi,
			es.snr as avg_snr,

			mess.last_reading_at,
			mess.zaehlerstand_bezug_kwh,
			mess.zaehlerstand_einspeisung_kwh,
			mess.zaehlerstand_wasser_m3,

			--dateadd(SECOND,sende_interval_sec,last_reading_at) as next_reading_expected,
			case
				when mess.last_reading_at is null then 'false'
				when cast(dateadd(SECOND,sende_interval_sec, mess.last_reading_at) as datetime) < dateadd(day,-1,getdate()) then 'false'
				else 'true'
			end as lora_online
		from 
			element_stage es
		left join
			last_readings mess on es.id_messpunkt = mess.id_messpunkt 
		where
			parser_id in ('d0198023-f115-4cf3-83aa-f3584afe5282', '7718461f-13f0-4dbe-9085-fc1d36770686','9e10001f-56e5-402a-b3ef-07824bb8efd3', 'a30b97a8-8372-4650-80d7-e6c3f3449ef6')

	), 
	lagerstatus as ( 
		
			select
				wert as id_lagerstatus,
				definition as lagerstatus
			from
				core.schluesseldefinition
			where
				feldname = 'zae_lagerstatus'
	)
	select
		ea.energieart,
		--
		e.zaehlernummer,
		e.device_name,
		e.inserted_at,
		e.sende_interval_sec,
		e.sf,
		e.avg_rssi,
		e.avg_snr,
		e.last_reading_at,
		e.zaehlerstand_bezug_kwh,
		e.zaehlerstand_einspeisung_kwh,
		e.zaehlerstand_wasser_m3,
		e.lora_online,
		--
		ztp.geraetetyp,
		lager.lagerstatus,
		cast(lzz.ZPG_EINBAUDATUM as date) as einbaudatum,
		zp.meteringcode,
		abnahmestelle_adresse,
		abnahmestelle_lat,
		abnahmestelle_lon,
		abnahmestelle_location_type,
		knd.kunden_nummer as monatskunde
	from 
		element e
	join
		core.energiearten ea on e.id_energieart = ea.id_energieart
	left join
		raw.wilken_enzaehler zae on e.zaehlernummer = zae.ZAE_NR
	left join
		lagerstatus lager on zae.ZAE_LAGERSTATUS = lager.id_lagerstatus
	left join
		core.geraetetypen ztp on zae.ZTP_NR = ztp.quellsystem_ident and zae.MND_ID = ztp.id_mandant and ztp.id_quellsystem = 1 -- wilken
	left join
		raw.wilken_enzptgeraet lzz on zae.MND_ID = lzz.MND_ID and zae.ZAE_ID = lzz.ZAE_ID and ZPG_STATUS = 1
	left join
		core.zaehlpunkte zp on zae.MND_ID = zp.id_mandant and zae.ZAE_ENERGIEART = zp.id_energieart and lzz.ZPT_ID = zp.wilken_zpt_id
	left join
		monatskunden knd on knd.id_mandant = zp.id_mandant and knd.id_zp = zp.id_zp 


GO
