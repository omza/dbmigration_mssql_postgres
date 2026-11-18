-- Object: stage.wilken_zaehlpunkt_geolocation
-- Type  : VIEW


/*
	ermittelt aus der raw tabelle address_geolocation und der dimension core.zaehlpunkte
	für jeden Zählpunkt die aktuelle Geolocation lat/lon in DD für die Abnahmestelle 

	14.07.2025	OMe	Initial

	select * from [stage].[wilken_zaehlpunkt_geolocation]

*/
CREATE view [stage].[wilken_zaehlpunkt_geolocation] as

	with loc as (
		
		select 
			*
			,ROW_NUMBER() over (partition by [address] order by 
				
				case 
					when [location_type] = 'ROOFTOP' then 1
					when [location_type] = 'RANGE_INTERPOLATED' then 2
					when [location_type] = 'GEOMETRIC_CENTER' then 3
					when [location_type] = 'APPROXIMATE' then 4
					else 5
				end

			) as best_loc
		from
			[raw].[address_geolocation]

	)
	SELECT 
		  zp.id_zp
		  ,isnull(try_cast(loc.[lat] as decimal(11,8)),zp.abnahmestelle_lat) as abnahmestelle_lat
		  ,isnull(try_cast(loc.[lng] as decimal(11,8)),zp.abnahmestelle_lon ) as abnahmestelle_lon
		  ,isnull(loc.[location_type], zp.abnahmestelle_location_type) as abnahmestelle_location_type
	FROM 
		core.zaehlpunkte zp
	left join
		loc on zp.abnahmestelle_adresse = loc.address and best_loc = 1

GO
