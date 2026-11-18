-- Object: stage.wilken_zaehlpunkt_fallgruppe
-- Type  : VIEW




/*
	ermittelt aus der raw tabelle wilken_enzmk die letzt gültige fallgruppe je zählpunkt

	21.07.2025	OMe	Initial

	select * from [stage].[wilken_zaehlpunkt_fallgruppe]

*/
CREATE view [stage].[wilken_zaehlpunkt_fallgruppe] as

	with zp_fallgruppe as (
	
		select
			[ZPT_ID] as id_zp
			,cast([ZMK_GRUPPE] as int) as id_fallgruppe
			,[ZMK_DURCHSCHNITTSVERBRAUCH] as fallgruppe_durchschnittsverbrauch
			,cast ([ZMK_VERBRZEITRAUMVON] as date) as fallgruppe_von
			,cast ([ZMK_VERBRZEITRAUMBIS] as date) as fallgruppe_bis
			,row_number() over (partition by ZPT_ID order by [ZMK_VERBRZEITRAUMBIS] desc) as reihenfolge

		from
			[raw].[wilken_enzmk]
	

		)
		select distinct
			fg.id_zp
			,dev.id_fallgruppe
			,fg.fallgruppe_durchschnittsverbrauch
			,fg.fallgruppe_von
			,fg.fallgruppe_bis	  
		from 
			zp_fallgruppe fg
		join
			core.fallgruppen dev on fg.id_fallgruppe = dev.id_fallgruppe
		where 
			reihenfolge = 1

GO
