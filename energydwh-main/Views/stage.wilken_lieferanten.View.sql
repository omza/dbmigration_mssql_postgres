-- Object: stage.wilken_lieferanten
-- Type  : VIEW





CREATE view [stage].[wilken_lieferanten] as

	select 
		  cast([lif_id] as int) id_lieferant
		  ,cast([mnd_id] as int) id_mandant
		  ,cast([ene_id] as int) id_energieart
		  ,[lif_name] as lieferant
		  ,[lif_kurzname] as lieferant_kurz
		  ,[lif_eic_nr] as eic_nummer
		  ,cast([knd_id] as int) id_kunde
		  ,cast([lif_aktiv] as int) flag_aktiv
		  ,LIF_ANGELEGT as created_at
		  ,isnull(LIF_GEAENDERT,LIF_ANGELEGT) as changed_at
	from 
		[raw].[wilken_enlieferant] 


GO
