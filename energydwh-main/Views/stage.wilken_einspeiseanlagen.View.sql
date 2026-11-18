-- Object: stage.wilken_einspeiseanlagen
-- Type  : VIEW





/*

	einspeiseanlagen aus wilken zusammenstellen

	change log
	----------
	22.09.2026	OMe	Initial
    23.09.2026  OMe Installierte Leistung hinzu

    test
    ----
    select * from [stage].[wilken_einspeiseanlagen] order by id_ressource 


*/

CREATE view [stage].[wilken_einspeiseanlagen] as

    with netzverknuepfungspunkt as (

        select 
            [mnd_id]
            ,nv.[envp_id]
            ,nva.eanl_id 
            ,[envp_bezeichnung]
            ,nva.eanv_gueltigab
            ,nva.eanv_gueltigbis
            ,row_number() over (partition by nva.eanl_id order by nva.eanv_gueltigab desc) rang
        from 
            [raw].[wilken_enespnetzverknuepfungspunkt] nv
        join

            [raw].[wilken_enespanlnvp] nva 
        on  
            nv.[envp_id] = nva.envp_id

    ), einspeisezaehlpunkt as (

        select 
            [eanl_id]
            ,[zpt_id]

                /*

                Definiert in welcher Beziehung die
                Anlage zum entsprechenden
                Zählpunkt steht.
                Jede Anlage hat eine gültige
                Zählpunktanlage mit Typ 1 und
                beliebig viele weitere <> Typ 1.
                Mögliche Werte: 
                1: Einspeisezählpunkt
                2: Erzeugungszählpunkt
                3: Eigenverbrauchszählpunkt
                4: Wärmemessungszählpunkt
                5: Einspeiseabzugszählpunkt

                */
            ,[ezpa_typ]
            ,[ezpa_beginn]

         from 
            [energydwh].[raw].[wilken_enespzptanlage]
         where 
            [ezpa_typ] = 1 -- 
            and isnull([ezpa_ende],getdate())>= getdate()

    ),

    stromerzeugungseinheit as (

        select 
	        eanl_id,
	        easee_mastrnr,
	        [easee_registrierungs_datum],
	        [easee_zugeordnet_von],
	        tre_id
        from 
	        [raw].[wilken_enespanlstromerzeugungseinheit]
        where
	        getdate() between [easee_zugeordnet_von] and isnull([easee_zugeordnet_bis],getdate())
    ),

    installierteleistung as (

        select   
            [eanl_id]
            ,[ead_gueltigab]
            ,[ead_typ]
            ,case 
                /*
                mögliche werte: 
                0: initialzustand
                1: modernisierung
                2: sonstiges
                */
                when [ead_typ] = 0 then 'initialzustand'
                when [ead_typ] = 1 then 'modernisierung'
                when [ead_typ] = 2 then 'sonstiges'
            end einspeiseanlage_aenderungstyp
            ,cast([ead_instleistung] as decimal(12,3)) as installierte_leistung
            ,row_number() over (partition by [eanl_id] order by [ead_gueltigab] desc) rang
        from 
            [raw].[wilken_enespanldaten]        
    )

    select  
          cast(anl.[eanl_id] as int) id_einspeiseanlage
          ,cast(anl.[mnd_id] as int) id_mandant
          ,cast(anl.[zpt_id] as int) id_zp

          ,cast(ezp.ZPT_ID as int) id_zp_einspeisezaehlpunkt
          ,cast(ezp.[ezpa_beginn] as date) einspeisezaehlpunkt_gueltig_ab

          ,cast([abn_id] as int) id_abn
          ,cast([eanl_nr] as varchar(33))  einspeiseanlage
          ,cast([EETR_BEZEICHNUNG] as varchar(40)) energietraeger
          ,cast([eanl_status] as int) id_status
          ,case 
            /*
            Mögliche Werte: 
            0: Inaktiv
            1: Aktiv
            2: Storniert
            3: In Bearbeitung / in Vorbereitung
            */
                when [eanl_status] = 0 then 'Inaktiv'
                when [eanl_status] = 1 then 'Aktiv'
                when [eanl_status] = 2 then 'Storniert'
                when [eanl_status] = 3 then 'In Bearbeitung / in Vorbereitung'
           end status
          ,cast([eanl_storniert] as date) storniert_am
          ,cast([eanl_einspeiseart] as int) as id_einspeiseart
          ,case 
            /*
                Mögliche Werte: 
                1: EEG-Anlage
                2: KWK G-Anlage
                3: Sonstige Einspeiseanlage
                4: Speicher
            */
                when [eanl_einspeiseart] = 1 then 'EEG-Anlage'
                when [eanl_einspeiseart] = 2 then 'KWK G-Anlage'
                when [eanl_einspeiseart] = 3 then 'Sonstige Einspeiseanlage'
                when [eanl_einspeiseart] = 4 then 'Speicher'
           end einspeiseart

          ,cast(il.einspeiseanlage_aenderungstyp as varchar(15)) as einspeiseanlage_aenderungstyp
          ,il.installierte_leistung

          ,cast([eanl_bnetzaschluessel] as varchar(33)) bnetza_eeg_schluessel
          ,cast([eanl_bnetzameldedatum] as date) bnetzameldedatum
          ,cast([eanl_aso_nr] as varchar(20)) as bnetza_aso_nr
          ,cast([eanl_mastrnr] as varchar(20)) as marktstammdatenregister_nummer
          ,cast([eanl_mastrnr_reg_datum] as date) marktstammdatenregister_registriert_am
          
          ,cast(nvp.ENVP_ID as int) as id_nvp
          ,cast(nvp.[envp_bezeichnung] as varchar(50)) as netzverknuepfungspunkt
          ,cast(eanv_gueltigab as date) as nvp_gueltig_ab


          ,cast([eanl_inbetriebnahme] as date) inbetriebnahme
          ,cast([eanl_stilllegungsdatum] as date) stilllegungsdatum
          ,cast([eanl_netzzugang] as date) netzzugang
          ,cast([eanl_netzabgang] as date) netzabgang
          ,cast([eanl_aufnahme_dauerbetrieb] as date) aufnahme_dauerbetrieb

	      ,cast (see.easee_mastrnr as varchar(20)) stromerzeugungseinheit_mastnr_nummer
	      ,cast([easee_registrierungs_datum] as date) stromerzeugungseinheit_mastnr_registriert_am
	      ,cast([easee_zugeordnet_von] as date) stromerzeugungseinheit_gueltig_ab
	      ,cast(tre_id as int) id_ressource

          ,cast([eanl_angelegt] as datetime) as created_at
          ,cast(isnull([eanl_geaendert],[eanl_angelegt]) as datetime) as changed_at


    from
        raw.wilken_enespanlage anl

    join
        raw.[wilken_enespenergietraeger] et
    on
        anl.[mnd_id] = et.[MND_ID]
        and anl.EETR_NR = et.EETR_NR
        and anl.EANL_EINSPEISEART = et.[EETR_EINSPEISEART]

    left join
        netzverknuepfungspunkt nvp
    on
        anl.[mnd_id] = nvp.MND_ID
        and anl.[eanl_id] = nvp.EANL_ID
        and nvp.rang = 1

    left join
        einspeisezaehlpunkt ezp on anl.EANL_ID = ezp.EANL_ID

    left join
        stromerzeugungseinheit see on anl.EANL_ID = see.EANL_ID

    left join
        installierteleistung il on anl.EANL_ID = il.EANL_ID and il.rang = 1


GO
