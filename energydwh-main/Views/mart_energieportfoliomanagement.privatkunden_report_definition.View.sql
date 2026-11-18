-- Object: mart_energieportfoliomanagement.privatkunden_report_definition
-- Type  : VIEW


--select * from [mart_energieportfoliomanagement].[privatkunden_report_definition] where kundengruppe = 2 order by sort





CREATE view [mart_energieportfoliomanagement].[privatkunden_report_definition] as

	with produktnamen as (

		select 
			id_energieart
			,produkt_nummer
			,min(produkt) as produkt
		from 
			core.produkte
		group by
			id_energieart
			,produkt_nummer			
	)
	
	select 
		def.[id_energieart]
		,kundengruppe
		,def.[produkt_nummer]
		,pn.produkt as produktname
		,[sort]
		,[ueberschrift1]
		,[ueberschrift2]
		,zusammenfassung
		,[prognosewert]
		,[kwh_staffel_von]
		,[kwh_staffel_bis]

	from 
		[stage].[privatkunden_report_definition] def

	join
		produktnamen pn on def.id_energieart = pn.id_energieart and def.produkt_nummer = pn.produkt_nummer
		


GO
