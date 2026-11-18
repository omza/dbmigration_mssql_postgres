-- Object: stage.wilken_link_zaehlpunkt_geraet
-- Type  : VIEW

/*

	change log
	----------

	15.12.2025	OMe Initial

	Test
	----
	select top 100 * from [stage].[wilken_link_zaehlpunkt_geraet] order by id_zp, einbaudatum


*/
CREATE view [stage].[wilken_link_zaehlpunkt_geraet] as


	SELECT
		cast(ZPG_ID as int) id_link_zp_geraet
		,cast([MND_ID] as int) id_mandant
		,cast([MENE_ID] as int) as id_energieart
		,cast([ZPT_ID] as int) id_zp
		,g.id_geraet

		,cast([ZPG_EINBAUDATUM] as date) as einbaudatum
		,cast(isnull([ZPG_AUSBAUDATUM],'9999-12-31') as date) as ausbaudatum
		,cast(ZPG_STATUS as int) as id_status 
		,case ZPG_STATUS
			when 1 then 'Aktiv'
			when 2 then 'Gewechselt'
			when 3 then 'Ausgebaut'
			when 5 then 'Geplant'
			when 9 then 'Storniert'
			else 'unbekannt'
		end as status

		,cast ([ZPG_ANGELEGT] as date) as created_at
		,cast (isnull([ZPG_GEAENDERT],[ZPG_ANGELEGT])  as date) as changed_at
		,case when ZPG_AUSBAUDATUM is null and ZPG_STATUS = 1 then 1 else 0 end as active
	FROM 
		[raw].[wilken_enzptgeraet] zpg
	join
		core.geraete g on CASE 
							when ZAE_ID is null THEN CONVERT(VARCHAR(32), HashBytes('MD5', 'INFO' + CAST(zpg.ZPG_ZAE_NR as varchar) + CAST(zpg.ZPG_ID as varchar)), 2)
							else CONVERT(VARCHAR(32), HashBytes('MD5', cast(zpg.ZAE_ID as varchar)), 2)
						end	= g.id_geraet
	where
		ZPT_ID is not null
		and (ZAE_ID is not null or ZPG_ZAE_NR is not null )


GO
