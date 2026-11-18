-- Object: stage.wilken_messstellenbetreiber
-- Type  : VIEW


/*

	select * from [stage].[wilken_messstellenbetreiber] where eigener_messstellenbetreiber = 1


*/

CREATE view [stage].[wilken_messstellenbetreiber] as

    select
        cast([mbt_id] as int) as id_messstellenbetreiber
        ,cast([mnd_id] as int) as id_mandant
        ,cast([ene_id] as int) as id_energieart
        ,cast([mbt_name] as varchar(50)) as messstellenbetreiber
        ,cast([mbt_eigen] as int) as eigener_messstellenbetreiber
        ,cast([mbt_aktiv] as int) as aktiver_messstellenbetreiber
        ,cast([knd_id] as int) as id_kunde

        ,cast(mbt.[mbt_angelegt] as datetime) as created_at
        ,isnull(mbt.[mbt_geaendert],mbt.[mbt_angelegt]) as changed_at
  
    from 
        [raw].[wilken_enmessstellenbetreiber] mbt

    union -- unbekannt

    select 
        -1 as id_messstellenbetreiber
        ,0 id_mandant
        ,0 as id_energieart
        ,'unbekannt' as messstellenbetreiber
        ,0 as eigener_messstellenbetreiber
        ,0 as aktiver_messstellenbetreiber
        ,NULL id_kunde

        ,getdate() as created_at
        ,getdate() as changed_at


   

GO
