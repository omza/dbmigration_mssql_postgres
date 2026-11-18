-- Object: core.abnahmestellen
-- Type  : VIEW



/*
	ermittelt aus den core tabellen die Abnahmestellendaten 

	01.09.2026	OMe	Initial
	09.09.2026	OMe	Je Energieart gruppieren
	10.09.2026	OMe	besser Kommentieren

	select * from [core].[abnahmestellen] order by abnahmestelle_adresse

*/
CREATE view [core].[abnahmestellen] as

	with abn as (

		select 
			id_energieart
			,[id_abn]		
			,[id_mandant]
			,[abnahmestelle_status]
			,[abnahmestelle_adresse]
			,[abnahmestelle_straße]
			,[abnahmestelle_hausnummer]
			,[abnahmestelle_hausnummer_zusatz]
			,[abnahmestelle_plz]
			,[abnahmestelle_ort]
			,max([abnahmestelle_lat]) as [abnahmestelle_lat]
			,max([abnahmestelle_lon]) as [abnahmestelle_lon]
			,count(distinct id_zp) as anzahl_melos 
		from
			core.zaehlpunkte
		where
			id_abn > 0
		group by
			id_energieart
			,[id_abn]		
			,[id_mandant]
			,[abnahmestelle_adresse]
			,[abnahmestelle_status]
			,[abnahmestelle_straße]
			,[abnahmestelle_hausnummer]
			,[abnahmestelle_hausnummer_zusatz]
			,[abnahmestelle_plz]
			,[abnahmestelle_ort]
	),

	nelos as (

		select 
			[id_mandant]
			,[id_abn]
			,[id_netzlokation]
			,[netzlokation]
			,[lokationsbuendel_status]
		from 
			[core].[lokationsbuendel]
		group by
			[id_mandant]
			,[id_abn]
			,[id_netzlokation]
			,[netzlokation]
			,[lokationsbuendel_status]
	)
	select
		abn.id_energieart
		,abn.[id_abn]		
		,abn.[id_mandant]
		,[abnahmestelle_status]
		,[abnahmestelle_adresse]
		,[abnahmestelle_straße]
		,[abnahmestelle_hausnummer]
		,[abnahmestelle_hausnummer_zusatz]
		,[abnahmestelle_plz]
		,[abnahmestelle_ort]
		,[abnahmestelle_lat]
		,[abnahmestelle_lon]
		,anzahl_melos 	
		--
		,[id_netzlokation]
		,[netzlokation]
		,[lokationsbuendel_status]

	from
		abn 
	
	left join
		nelos on abn.id_abn = nelos.id_abn	and abn.id_mandant = nelos.id_mandant


GO
