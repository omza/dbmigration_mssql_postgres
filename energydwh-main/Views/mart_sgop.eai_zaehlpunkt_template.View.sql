-- Object: mart_sgop.eai_zaehlpunkt_template
-- Type  : VIEW
/*

	-- Schnittstellen felder

		Name
		EnergyFlow
		ParentMeteringPointName
		GisReferenceLinkedElement
		FlexibilityIdentifiers
		AnnualEnergyQuantityConsumptionPairs
		AnnualEnergyQuantityProductionPairs
		ConsumptionLoadProfileIds
		ProductionLoadProfileIds







	-- test
	select * from [mart_sgop].eai_zaehlpunkt_template order by id_abn, id_lokationsbuendel, ParentMeteringPointName

*/
CREATE view [mart_sgop].eai_zaehlpunkt_template
as

    with parent as (

        select distinct
            id_lokationsbuendel_zeitscheibe,
            id_ebene,
            zp.meteringcode as ParentMeteringPointName
        from
            [core].[lokationsbuendel] lb
        join
            core.zaehlpunkte zp 
        on 
            lb.id_zp = zp.id_zp
            and lb.id_mandant = zp.id_mandant
        where 
            lb.id_lokationsbuendel_status = 1
            and getdate() between lb.[gueltig_ab] and lb.[gueltig_bis]

    )
    select  distinct
        lb.id_abn,
        lb.id_lokationsbuendel,

        -- export
        zp.meteringcode as [name]

        ,case 
            when lb.id_richtung = 1 then 'Consumer'
            when lb.id_richtung = 2 then 'Producer'
            when lb.id_richtung = 3 then 'Prosumer'
        end as EnergyFlow


        ,lbparent.ParentMeteringPointName
     
        ,lb.[netzlokation] as gisreferencelinkedelement
        ,null as  flexibilityidentifiers

		,null AnnualEnergyQuantityConsumptionPairs
		,null AnnualEnergyQuantityProductionPairs
		,null ConsumptionLoadProfileIds
		,null ProductionLoadProfileIds

    from 
        [core].[lokationsbuendel] lb

    join
        core.zaehlpunkte zp 
    on 
        lb.id_zp = zp.id_zp
        and lb.id_mandant = zp.id_mandant

    join
        core.lokationsbuendelstruktur lbs on lb.id_lokationsbuendelstruktur = lbs.id_lokationsbuendelstruktur

    left join
        parent lbparent 
    on
        lb.id_lokationsbuendel_zeitscheibe = lbparent.id_lokationsbuendel_zeitscheibe
        and lb.id_ebene-1 = lbparent.id_ebene

    where 
        lb.id_lokationsbuendel_status = 1
        and getdate() between lb.[gueltig_ab] and lb.[gueltig_bis]
        -- zp niederspannung
        and zp.id_energieart = 1 --strom
        --and zp.id_spannungsebene in (-1,4,11) --niederspannung	
        and lb.netzlokation is not null



GO
