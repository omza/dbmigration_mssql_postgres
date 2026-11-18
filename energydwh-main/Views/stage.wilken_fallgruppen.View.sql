-- Object: stage.wilken_fallgruppen
-- Type  : VIEW




/*
	ermittelt aus der raw tabelle wilken_enzmk die letzt gültige fallgruppe je zählpunkt

	22.07.2025	OMe	Initial

	select * from [stage].[wilken_fallgruppen] where id_zp = 23897 order by id_zp, active desc, fallgruppe_von desc

	fallgruppendefinition aus Datenbeschreibung wilken energy

		id_fallgruppe	id_mandant	id_energieart	id_energierichtung	fallgruppe
		0	1	NULL	NULL	unbestimmt
		1	1	1	1	>100000 kWh
		2	1	1	1	> 50000 bis 100000 kWh
		3	1	1	1	> 20000 bis 50000 kWh
		4	1	1	1	> 10000 bis 20000 kWh
		5	1	1	1	> 6000 bis 10000 kWh
		6	1	1	1	> 4000 bis 6000 kWh
		7	1	1	1	> 3000 bis 4000 kWh
		8	1	1	1	> 2000 bis 3000 kWh
		9	1	1	1	Bis 2000 kWh
		10	1	1	1	§ 14a Steuerbare Verbrauchseinrichtungen
		11	1	1	2	> 100 kW
		12	1	1	2	> 30 bis 100 kW
		13	1	1	2	> 15 bis 30 kW
		14	1	1	2	> 7 bis 15 kW
		15	1	1	2	> 1 bis 7 kW
		16	1	1	1	Bis 3000 kWh
		17	1	1	1	> 3000 bis 6000 kWh
		18	1	1	2	> 25 bis 100 kW
		19	1	1	2	> 15 bis 25 kW
		20 1    1   2   < 1 bis 1 kW


*/
CREATE view [stage].[wilken_fallgruppen] as

	with zp_fallgruppe as (
	
		select
			[KEY] as id
			,[ZPT_ID] as id_zp
			,case when ZMK_LIEFERRICHTUNG = 1 then 2 else 1 end id_energierichtung
			,cast([ZMK_GRUPPE] as int) as id_fallgruppe
			,[ZMK_DURCHSCHNITTSVERBRAUCH] as fallgruppe_durchschnittsverbrauch
			,cast ([ZMK_VERBRZEITRAUMVON] as date) as fallgruppe_von
			,cast ([ZMK_VERBRZEITRAUMBIS] as date) as fallgruppe_bis
			,row_number() over (partition by ZPT_ID, [ZMK_LIEFERRICHTUNG] order by [ZMK_VERBRZEITRAUMBIS] desc) as reihenfolge

			,cast ([ZMK_ERMITTELT_AM] as date) as ermittelt_am
			,cast([ZMK_ANGELEGT] as datetime) as created_at
			,cast(isnull([ZMK_GEAENDERT],[ZMK_ANGELEGT]) as datetime) as changed_at
		from
			[raw].[wilken_enzmk]
	

		)
		select
			id
			,id_zp
			,id_energierichtung
			,id_fallgruppe
			,case 
				when id_fallgruppe = 1 then '>100000 kWh'
				when id_fallgruppe = 2 then '> 50000 bis 100000 kWh'
				when id_fallgruppe = 3 then '> 20000 bis 50000 kWh'
				when id_fallgruppe = 4 then '> 10000 bis 20000 kWh'
				when id_fallgruppe = 5 then '> 6000 bis 10000 kWh'
				when id_fallgruppe = 6 then '> 4000 bis 6000 kWh'
				when id_fallgruppe = 7 then '> 3000 bis 4000 kWh'
				when id_fallgruppe = 8 then '> 2000 bis 3000 kWh'
				when id_fallgruppe = 9 then 'Bis 2000 kWh'
				when id_fallgruppe = 10 then '§ 14a Steuerbare Verbrauchseinrichtungen'
				when id_fallgruppe = 11 then '> 100 kW'
				when id_fallgruppe = 12 then '> 30 bis 100 kW'
				when id_fallgruppe = 13 then '> 15 bis 30 kW'
				when id_fallgruppe = 14 then '> 7 bis 15 kW'
				when id_fallgruppe = 15 then '> 1 bis 7 kW'
				when id_fallgruppe = 16 then 'Bis 3000 kWh'
				when id_fallgruppe = 17 then '> 3000 bis 6000 kWh'
				when id_fallgruppe = 18 then '> 25 bis 100 kW'
				when id_fallgruppe = 19 then '> 15 bis 25 kW'
				when id_fallgruppe = 20 then '< 1 bis 1 kW'
				else 'unbekannt'
			end fallgruppe
			,fallgruppe_durchschnittsverbrauch
			,ermittelt_am
			,fallgruppe_von
			,fallgruppe_bis
			,case when reihenfolge = 1 then 1 else 0 end active
			,created_at
			,changed_at
		from 
			zp_fallgruppe fg



GO
