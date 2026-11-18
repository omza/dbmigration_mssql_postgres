-- Object: stage.nedi_ipueps_saga_power
-- Type  : VIEW

/*

	Ersatz für powerswitch db - Berechnungslogik von Frank Schmöller nachgebaut
	für Rainer Hoff

	change log
	----------
	04.11.2026	OMe	initial

	test
	----
	select 
		*, 
		power_card + power_chassis + power_mgmt as power_sum  
	from [stage].[nedi_ipueps_saga_power]

*/
CREATE view [stage].[nedi_ipueps_saga_power] as

	with customer as (

		select 
			device,
			count(ifstat) as customer
		from 
			raw.nedi_interfaces 
		where  
			ifdesc LIKE '%vdsl%' 
			and ifstat = '3'
		group by
			device

	),

	nedi_power(type, model, power_model, power_chassis, power_mgmt ) as (

		select * from (values 
			('ves-1616fe-55a', null, 14.5, 0.0, 0.0),
			('ves-1616fe-53a', null, 14.5, 0.0, 0.0),
			('ves1608fe-57', null, 17.5, 0.0, 0.0),
			('ves1724-56', null, 26.2, 0.0, 0.0),
			('ves1724-56b2', null, 18.8, 0.0, 0.0),

			('ies-5005', 'vlc1324g-53', 23.4, 21.7, 14.7),
			('ies-5005', 'vlc1348g-53', 33.8, 21.7, 14.7),
			('ies-5005', 'vlc1348g-51', 33.8, 21.7, 14.7),

			('ies-5106', 'vlc1324g-53', 23.4, 30.0, 18.5),
			('ies-5106', 'vlc1348g-53', 33.8, 30.0, 18.5),
			('ies-5106', 'vlc1348g-51', 33.8, 30.0, 18.5)

		) as t(a, b, c, d, e) -- internal aliases are required but ignored by the cte definition



	),

	modules as (

		select
			device,
			model,
			count(*) as card
		from 
			raw.nedi_modules modules

		where 
			model LIKE '%vlc%'	
		group by
			device,
			model	

	),

	ipueps_cards as (

		select
			LTRIM(RTRIM(ndev.device)) as messpunkt_ident,
			LEFT(ndev.serial,50) as messpunkt_serialnummer,
			LEFT(REPLACE(ndev.description,'/'+LTRIM(RTRIM(ndev.type)),''),50) as messpunkt_name,
			LEFT(ndev.vendor + ' ' +ndev.type,50) as messpunkt_beschreibung,
			LEFT(ndev.location,100) as location_beschreibung,
			case when charindex(';',reverse(ndev.location)) > 1 then
				reverse(Left(reverse(ndev.location),charindex(';',reverse(ndev.location))-1))
			else null end lat_lon,
			cast(ndev.devstatus as int) as messpunkt_status,
			ndev.type as switch_type,
			cast(isnull(cust.customer,0) as int) as customer_count,
			LEFT(isnull(modules.model,''),64) as card_type,
			cast(isnull(modules.card,1) as int) as card_count,
			pwr.power_model as power_card,
			pwr.power_chassis,
			pwr.power_mgmt
		FROM 
			raw.nedi_devices ndev 
        
		JOIN
			[raw].[nedi_inventory] inv on (ndev.serial = inv.serial)

		left join
			customer cust on ndev.device = cust.device

		left join
			modules on ndev.device = modules.device

		left join
			nedi_power pwr on lower(ndev.type) = pwr.type and lower(isnull(modules.model,'')) = isnull(pwr.model,'')

		where 
			description LIKE '%IPUEP%' 
			and (inv.maintpartner = 'wtnet' or inv.maintpartner = '')
			and ndev.type not LIKE '%ECS%'
	)
	select 
		[messpunkt_ident]
		,[messpunkt_serialnummer]
		,[messpunkt_name]
		,[messpunkt_beschreibung]
		,[location_beschreibung]
		,[lat_lon]
		,[messpunkt_status]
		,switch_type
		,max([customer_count]) as customer_count
		--,[card_type]
		,sum([card_count]) as card_count
		,sum([card_count] * [power_card]) as power_card
		,max([power_chassis]) as [power_chassis]
		,max([power_mgmt]) as [power_mgmt]
	from 
		ipueps_cards
	group by
		[messpunkt_ident]
		,[messpunkt_serialnummer]
		,[messpunkt_name]
		,[messpunkt_beschreibung]
		,[location_beschreibung]
		,[lat_lon]
		,[messpunkt_status]
		,switch_type



GO
