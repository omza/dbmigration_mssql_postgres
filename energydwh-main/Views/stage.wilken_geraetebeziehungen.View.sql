-- Object: stage.wilken_geraetebeziehungen
-- Type  : VIEW




/*
	gerätebeziehungen mit definition und verlinkten geräten

	change log:
	----------
	26.03.2026	OME	initial
	22.06.2026	OMe	Vorbereitung für core_link_geraet_geraet
	23.06.2026	OMe	Fix slave verküpfung


	test:
	----
	select * from [stage].[wilken_geraetebeziehungen]

*/
CREATE view [stage].[wilken_geraetebeziehungen] as

	select
		cast(b.GBZ_ID as int) as id_link_geraet_geraet
		,1 as id_quellsystem --wilken
		--,cast(ZPG_ID_MASTER as int) as master_quellsystem_ident
		--,cast(ZPG_ID_SLAVE as int) as slave_quellsystem_ident
		,cast(bd.GBZD_ID as int) as id_beziehnungsart
		,cast(bd.GBZD_BEZEICHNUNG as varchar(50)) as beziehungsart
		,convert(date, b.GBZ_GUELTIGAB, 120) as gueltig_von
		,convert(date, isnull(b.GBZ_GUELTIGBIS,'9999-12-31'), 120) as gueltig_bis
		,cast(b.GBZ_STATUS as int) as id_status_geraetebeziehung

		-- Master
		,masg.id_geraet as master_id_geraet
		,mast.ZAE_ID as master_quellsystem_ident
		,mast.ZPG_ZAE_NR as master_geraetenummer
		,cast(mast.[MND_ID] as int) master_id_mandant
		,isnull(cast(mast.[MENE_ID] as int),0) as master_id_energieart
		,cast(mast.[ZPG_EINBAUDATUM] as date) as master_einbaudatum
		,cast(isnull(mast.[ZPG_AUSBAUDATUM],'9999-12-31') as date) as master_ausbaudatum
		,cast(mast.ZPG_STATUS as int) as master_id_status 
		,case mast.ZPG_STATUS
			when 1 then 'Aktiv'
			when 2 then 'Gewechselt'
			when 3 then 'Ausgebaut'
			when 5 then 'Geplant'
			when 9 then 'Storniert'
			else 'unbekannt'
		end as master_status

		-- Slave
		,slaveg.id_geraet as slave_id_geraet
		,slave.ZAE_ID as slave_quellsystem_ident
		,slave.ZPG_ZAE_NR as slave_geraetenummer
		,cast(slave.[MND_ID] as int) slave_id_mandant
		,isnull(cast(slave.[MENE_ID] as int),0)  as slave_id_energieart
		,cast(slave.[ZPG_EINBAUDATUM] as date) as slave_einbaudatum
		,cast(isnull(slave.[ZPG_AUSBAUDATUM],'9999-12-31') as date) as slave_ausbaudatum
		,cast(slave.ZPG_STATUS as int) as slave_id_status 
		,case slave.ZPG_STATUS
			when 1 then 'Aktiv'
			when 2 then 'Gewechselt'
			when 3 then 'Ausgebaut'
			when 5 then 'Geplant'
			when 9 then 'Storniert'
			else 'unbekannt'
		end as slave_status		

	from
		raw.wilken_engeraetebeziehung b

	join
		raw.wilken_engeraetebeziehungdef bd on b.GBZD_ID = bd.GBZD_ID

	join
		[raw].[wilken_enzptgeraet] mast on b.ZPG_ID_MASTER = mast.ZPG_ID

	left join
		core.geraete masg on CASE 
							when mast.ZAE_ID is null THEN CONVERT(VARCHAR(32), HashBytes('MD5', 'INFO' + CAST(mast.ZPG_ZAE_NR as varchar) + CAST(mast.ZPG_ID as varchar)), 2)
							else CONVERT(VARCHAR(32), HashBytes('MD5', cast(mast.ZAE_ID as varchar)), 2)
						end	= masg.id_geraet	

	join
		[raw].[wilken_enzptgeraet] slave on b.ZPG_ID_SLAVE = slave.ZPG_ID

	left join
		core.geraete slaveg on CASE 
								when slave.ZAE_ID is null THEN CONVERT(VARCHAR(32), HashBytes('MD5', 'INFO' + CAST(slave.ZPG_ZAE_NR as varchar) + CAST(slave.ZPG_ID as varchar)), 2)
								else CONVERT(VARCHAR(32), HashBytes('MD5', cast(slave.ZAE_ID as varchar)), 2)
							end	= slaveg.id_geraet	



GO
