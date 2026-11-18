-- Object: stage.wilken_geraete
-- Type  : VIEW




/*

	Change Log
	----------

	15.12.2025	OMe	initial
	18.06.2026	OMe	gasruck aus dem Regler hinzu


	Test
	----
	
	select top 200 * from [stage].[wilken_geraete] where gasdruck is not null

*/

CREATE view [stage].[wilken_geraete] as

	with lose as (
		select
			ZAE_ID,
			MND_ID,
			LOS_NR,
			LOS_NR_ZUSATZ,
			ROW_NUMBER() over (partition by ZAE_ID order by [ZLO_VERLJAHR] desc) as rang
		from 
			raw.wilken_enzaehlerlos
	),		
	geraete as (

		select distinct
			try_cast(z.MND_ID as int) id_mandant,
			CONVERT(VARCHAR(32), HashBytes('MD5', cast(z.ZAE_ID as varchar)), 2) as id_geraet,
			1 as id_quellsystem,
			z.ZAE_ID as quellsystem_ident,
			ZAE_NR geraetenummer,
			isnull(z.ZAE_ENERGIEART,0) as id_energieart,
			z.GER_ID as id_geraeteart,
			ztp.id_geraetetyp,
			isnull(sztp.id_standardgeraetetyp,0) [id_standardgeraetetyp],
			--try_convert(date,lzpg.ZPG_EINBAUDATUM,120) einbaudatum,
			--try_convert(date,lzpg.ZPG_AUSBAUDATUM,120) ausbaudatum,

			z.ZAE_BAUJAHR as baujahr,
			cast(z.ZAE_EICHJAHR as int) as eichung,
			cast(z.ZAE_NAECHSTESEICHJAHR as int) as naechste_eichung,
			los.LOS_NR + '(' + cast(los.LOS_NR_ZUSATZ as varchar) + ')' as los_nummer,
			ISNULL(z.ZAE_LOSSTATUS,0) as id_losstatus,
			z.ZAE_LAGERSTATUS as id_lagerstatus,
			zenr.ZENR_BEZEICHNUNG zaehler_energierichtungen,
			z.ZAE_PIN as zaehlerpin,

			z.ZAE_GASDRUCK as gasdruck,

			z.ZAE_ANGELEGT AS created_at,
			isnull(z.ZAE_GEAENDERT,z.ZAE_ANGELEGT) as changed_at
		from
			raw.wilken_enzaehler z 
		left join
			core.geraetetypen ztp on z.ZTP_NR = ztp.quellsystem_ident and z.MND_ID = ztp.id_mandant and ztp.id_quellsystem = 1 -- wilken
		left join
			core.geraetetypen_standard sztp on z.SZTP_NR = sztp.wilken_sztp_nr and z.MND_ID = sztp.id_mandant
		left join
			raw.wilken_enzenr zenr   on z.ZENR_NR = zenr.ZENR_NR and z.MND_ID = zenr.MND_ID
		left join
			lose los on z.ZAE_ID = los.ZAE_ID and z.MND_ID = los.MND_ID and los.rang = 1
	),
	zusatzdaten as (

		select 
			row_number() over (partition by [zpg_id] order by  [zpgd_gueltigab] desc) rang
			,*
		from [raw].[wilken_enzpgd]


	),
	geraeteinfosaetze as (

		select distinct
			try_cast(z.MND_ID as int) id_mandant,
			CONVERT(VARCHAR(32), HashBytes('MD5', 'INFO' + CAST(z.ZPG_ZAE_NR as varchar) + CAST(z.ZPG_ID as varchar)), 2) as id_geraet,
			1 as id_quellsystem,
			null as quellsystem_ident,
			z.ZPG_ZAE_NR geraetenummer,
			isnull(zp.id_energieart,0) as id_energieart,
			z.ZPG_GERAETEGRUNDTYP as id_geraeteart,
			ztp.id_geraetetyp,
			isnull(sztp.id_standardgeraetetyp,0) [id_standardgeraetetyp],
			--try_convert(date,lzpg.ZPG_EINBAUDATUM,120) einbaudatum,
			--try_convert(date,lzpg.ZPG_AUSBAUDATUM,120) ausbaudatum,

			null as baujahr,
			null as eichung,
			cast(z.ZPG_NAECHSTESEICHJAHR as int) as naechste_eichung,
			null as los_nummer,
			null as id_losstatus,
			z.ZPG_STATUS as id_lagerstatus,
			zenr.ZENR_BEZEICHNUNG zaehler_energierichtungen,
			null as zaehlerpin,
			null as gasdruck,
			z.ZPG_ANGELEGT AS created_at,
			isnull(z.ZPG_GEAENDERT,z.ZPG_ANGELEGT) as changed_at
		from
			raw.wilken_enzptgeraet z
		join
			zusatzdaten zd on z.ZPG_ID = zd.ZPG_ID and z.MND_ID = zd.MND_ID and zd.rang = 1
		left join
			core.geraetetypen_standard sztp on zd.SZTP_NR = sztp.wilken_sztp_nr and z.MND_ID = sztp.id_mandant
		left join
			raw.wilken_enzenr zenr   on zd.ZENR_NR = zenr.ZENR_NR and z.MND_ID = zenr.MND_ID
		left join
			core.geraetetypen ztp on 'INFO' = ztp.quellsystem_ident and z.MND_ID = ztp.id_mandant and ztp.id_quellsystem = 1 -- wilken
		left join
			core.zaehlpunkte zp on z.ZPT_ID = zp.id_zp and z.MND_ID = zp.id_mandant
		where
			ZAE_ID is null
			and ZPG_ZAE_NR is not null
			and ZPG_STATUS not in ( 9, 5 )
			and ZPG_AUSBAUDATUM is null
			--and ZPT_ID is not null

	),
	alle as (
		select * from geraete
		union
		select * from geraeteinfosaetze
	)
	
	select 
		[id_mandant]
		,[id_geraet]
		,[id_quellsystem]
		,[quellsystem_ident]
		,[geraetenummer]
		,[id_energieart]
		,[id_geraeteart]
		,[id_geraetetyp]
		,[id_standardgeraetetyp]
		,[baujahr]
		,[eichung]
		,[naechste_eichung]
		,[los_nummer]
		,[id_losstatus]
		,[id_lagerstatus]
		,[zaehler_energierichtungen]
		,[zaehlerpin]
		,gasdruck
		,[created_at]
		,[changed_at] 
	from 
		alle


GO
