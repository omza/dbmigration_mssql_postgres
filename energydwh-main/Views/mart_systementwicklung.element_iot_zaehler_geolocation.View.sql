-- Object: mart_systementwicklung.element_iot_zaehler_geolocation
-- Type  : VIEW




/*
	select * from [mart_systementwicklung].[element_iot_zaehler_geolocation]  
*/
CREATE view [mart_systementwicklung].[element_iot_zaehler_geolocation] 
	as


	with geraete as (

		select
			lzpg.ZPT_ID id_zp,
			try_cast(lzpg.MND_ID as int) id_mandant,
			lzpg.ZAE_ID id_zaehler,
			try_convert(date,lzpg.ZPG_EINBAUDATUM,120) einbaudatum,
			lzpg.ZPG_ZAE_NR zaehlernummer,
			lzpg.ZPG_ID
		from
			raw.wilken_enzptgeraet lzpg
		where
			lzpg.ZPG_STATUS <> 9
			and ZPG_ZAE_NR is not null	
		
	)
	select
		--zp.meteringcode,
		ea.energieart as Energieart,
		--zpt.zaehlpunkttyp,
		zaehlernummer as Zaehlernummer,
		zp.abnahmestelle_adresse as Abnahmestelle,
		--einbaudatum as Einbaudatum,
		zp.abnahmestelle_lat as Lat,
		zp.abnahmestelle_lon as Lon,
		zp.abnahmestelle_location_type as Location_Type
	from
		core.zaehlpunkte zp 
	join
		core.energiearten ea on zp.id_energieart = ea.id_energieart
	join
		core.zaehlpunkt_typen zpt on zp.id_zp_typ = zpt.id_zp_typ
	join
		geraete lzpg on zp.id_zp = lzpg.id_zp and zp.id_mandant = lzpg.id_mandant



GO
