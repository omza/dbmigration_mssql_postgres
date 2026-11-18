-- Object: mart_systementwicklung.element_iot_gateways
-- Type  : VIEW



/*
	select * from [mart_systementwicklung].[element_iot_gateways]  
*/
CREATE view [mart_systementwicklung].[element_iot_gateways] 
	as


	select
		load_at,
		case 
			when charindex('indoorgateways', slugs) > 0 then 'indoorgateways'
			when charindex('publicgateways-alle-gw', slugs) > 0 then 'publicgateways-alle-gw'
		end as lora_ordner,
		id,
		name,
		slug as device_slug,
		lat,
		lon,
		cast(replace([stage].[json_value_from_key](fields,'reichweite'),'reichweite:','') as varchar) as reichweite,
		cast(replace([stage].[json_value_from_key](fields,'switch_ip'),'switch_ip:','') as varchar) as switch_ip,
		cast(replace([stage].[json_value_from_key](fields,'port'),'port:','') as varchar) as port,
		updated_at,
		inserted_at
	from 
		[raw].[element_iot_devices]  
	where 
		charindex('publicgateways-alle-gw', slugs) > 0
		or charindex('indoorgateways', slugs) > 0 



GO
