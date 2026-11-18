-- Object: stage.wilken_zaehlpunkt_jahresverbrauch
-- Type  : VIEW




/*
	
    change log
    ----------
    19.10.2026  OMe Datenprüfung und Island/Gaps ermitteln
    21.10.2026  OMe letzten Datensatz je Messeinheit markieren

	test
	----
	select * from [stage].[wilken_zaehlpunkt_jahresverbrauch] where id_zp = 12 order by gueltig_von


*/
CREATE view [stage].[wilken_zaehlpunkt_jahresverbrauch] as

    with nt_mengen as (

        select
            *
        from
            [raw].[wilken_enzptma] ma
        where
           isnull(ma.vba_nr,0) in (1002,1005,10051)

    ), 

    abrechnungsmengen as (

        select 
            zp.id_energieart
              ,enz.mes_id
              ,enz.zpt_id
              ,enz.zptem_jahresverbrauchber
              ,isnull(ma.zptma_jahresverbrauchber,0) as jahresverbrauch_nt_ber
              ,[zptem_zeitraumvon]
              ,[zptem_zeitraumbis]
              ,datediff(day,[zptem_zeitraumvon],[zptem_zeitraumbis]) anzahl_tage
              ,zptem_angelegt as created_at
              ,isnull(zptem_geaendert, zptem_angelegt) as changed_at
    
            ,case 
                when zptem_zeitraumvon = dateadd(day, 1, lag(zptem_zeitraumbis) over (partition by zpt_id order by zptem_zeitraumvon))
                        and zptem_jahresverbrauchber = lag(zptem_jahresverbrauchber) over (partition by zpt_id order by zptem_zeitraumvon)
                then 0 else 1 
            end as isnewisland
            ,row_number() over (partition by enz.zpt_id, [zptem_zeitraumvon] order by isnull(zptem_geaendert, zptem_angelegt) desc) as sequence_nr -- nur den letzten Jatz je Zeitscheibe
            ,row_number() over (partition by enz.mes_id order by zptem_zeitraumvon desc) as rang -- letzte Zeitscheibe je messeinheit immer rang =1
          from 
            [energydwh].[raw].[wilken_enzptem] enz
          join
            core.zaehlpunkte zp on enz.zpt_id = zp.id_zp
           left join
            nt_mengen ma
                on enz.zptem_id = ma.zptem_id
          where 
            year([zptem_zeitraumbis]) >= 2015
            and zptem_art = 0 -- arbeit
            and enz.prz_id not in('5')
            and isnull(enz.zptem_jahresverbrauchber,0) > 0

    ),

    islandgroupcte as (

        select 
            *,
            cast(case when rang= 1 then 1 else 0 end as tinyint) as [messeinheit_letzte_zeitscheibe],
            -- erzeugt eine fortlaufende id für jede zusammenhängende gruppe
            sum(isnewisland) over (partition by zpt_id order by zptem_zeitraumvon) as islandid
        from 
            abrechnungsmengen
        where 
            sequence_nr = 1
    )

    select 
        cast(mes_id as int) as id_link_messeinheit, 
        cast(zpt_id as int) as id_zp, 
        id_energieart,
        zptem_jahresverbrauchber as jahresverbrauch_kwh_gesamt, 
        jahresverbrauch_nt_ber as jahresverbrauch_kwh_nt, 
        cast(min(zptem_zeitraumvon) as date) as gueltig_von, 
        cast(max(zptem_zeitraumbis) as date) as gueltig_bis, 
        sum(anzahl_tage) as abgerechnete_tage,
        [messeinheit_letzte_zeitscheibe],
        max(created_at) as created_at,
        max(changed_at) as changed_at
        
    from 
        islandgroupcte
    group by 
        id_energieart, 
        mes_id, 
        zpt_id, 
        zptem_jahresverbrauchber, 
        jahresverbrauch_nt_ber, 
        [messeinheit_letzte_zeitscheibe],
        islandid


GO
