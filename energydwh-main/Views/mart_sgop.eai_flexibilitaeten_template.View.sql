-- Object: mart_sgop.eai_flexibilitaeten_template
-- Type  : VIEW
/*

	-- Schnittstellen felder

    -- test
    select
        Identifier
        ,Name
        ,MaxPowerInKiloWatts
        ,MaxApparentPowerInKva
        ,CapacityInKiloWattHours
        ,FlexibilityTemplateName
        ,ControlPermission
        ,City
        ,Street
        ,Zip
        ,Country
        ,Longitude
        ,Latitude
        ,InstalledAt
        ,DisconnectedAt
        ,MeteringPointName
    from
        [mart_sgop].eai_flexibilitaeten_template
    order by 
        id_abn, id_lokationsbuendel, Identifier



	select * from [mart_sgop].eai_flexibilitaeten_template order by id_abn, id_lokationsbuendel, Identifier

*/
CREATE view [mart_sgop].eai_flexibilitaeten_template
as

    select  distinct
        lb.id_abn,
        lb.id_lokationsbuendel,
        tre.id_zp,
        lb.id_ressource,

        -- export
        tre.ressourcen_nummer as Identifier,
        [ressource_bemerkung] as [Name],
        case 
            when tre.ressource_nutzungsart = 'Erzeugung' then [nennleistung_kw_abgabe]
            else [nennleistung_kw_aufnahme]
        end as MaxPowerInKiloWatts,
        null as MaxApparentPowerInKva,
        case 
            when tre.ressource_nutzungsart = 'Speicher' then [speicherkapazitaet_kwh]
            else null
        end as CapacityInKiloWattHours,
        
        -- Mapping für Templates 
        case 
            when tre.ressource_nutzungsart = 'Speicher' then 'Batterie'
            when tre.ressource_nutzungsart = 'Erzeugung' and [ressource_erzeugungsart] = 'Solar' then 'Solaranlage'
            when tre.ressource_nutzungsart = 'Erzeugung' and [ressource_erzeugungsart] <> 'Solar' then 'unbekannt'
            when tre.ressource_nutzungsart = 'Verbrauch' and tre.waermenutzung is not null then 'Wärmepumpe'
            when tre.ressource_nutzungsart = 'Verbrauch' and [stromverbrauchsart] in ('E-Mobilität - E-Mobilitätsladesäule','Kraft/Licht/Wallbox', 'E-Mobilität - Wallbox', 'E-Mobilität - Ladepark') and isnull([nennleistung_kw_aufnahme],0) <= 50 then 'Ladestation'
            when tre.ressource_nutzungsart = 'Verbrauch' and [stromverbrauchsart] in ('E-Mobilität - E-Mobilitätsladesäule','Kraft/Licht/Wallbox', 'E-Mobilität - Wallbox', 'E-Mobilität - Ladepark') and isnull([nennleistung_kw_aufnahme],0) > 50 then 'Schnelllader'
            else 'unbekannt'
        end as FlexibilityTemplateName,


        isnull(tre.faellt_unter_enwg14a,1) as ControlPermission,
        zp.abnahmestelle_ort as City,
        zp.abnahmestelle_straße + ' ' + isnull(cast(zp.abnahmestelle_hausnummer as varchar),'') + isnull(zp.abnahmestelle_hausnummer_zusatz,'')  as Street,
        zp.abnahmestelle_plz as Zip,
        'Deutschland' as Country,
        null as Longitude,
        null as Latitude,
        convert(varchar(20),tre.ressource_gueltig_ab,104) + ' 00:00:00' as InstalledAt,
        convert(varchar(20),tre.ressource_gueltig_bis,104) + ' 00:00:00' as DisconnectedAt,
        zp.meteringcode as  MeteringPointName

        --
        --zp.*
    from 
        [core].[lokationsbuendel] lb 

    join
        core.technische_ressourcen tre
        
    on
        tre.id_mandant = lb.id_mandant
        and tre.id_ressource = lb.id_ressource

    join
        core.zaehlpunkte zp 
    on 
        tre.id_zp = zp.id_zp
        and tre.id_mandant = zp.id_mandant


    where 
        lb.id_lokationsbuendel_status = 1
        and lb.id_ressource > 0
        and getdate() between lb.[gueltig_ab] and lb.[gueltig_bis]
        and getdate() between tre.ressource_gueltig_ab and tre.ressource_gueltig_bis
        -- zp niederspannung
       and zp.id_energieart = 1 --strom
       --and zp.id_spannungsebene in (-1,4,11) --niederspannung	

       and zp.abnahmestelle_status = 1 -- nur gültige Abnahmestellen



GO
