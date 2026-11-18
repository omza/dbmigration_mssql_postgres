-- Object: mart_technische_doku.caigos_elektro_nelos_falsch_zugeordnet
-- Type  : VIEW





/*

    Nelo Schnittstelle per Adressabgleich mit Wilken Abnahmestellen verbinden
    Diese Abfrage liefert alle Caigos ehas, die per adressabgleich zugeordnet zu einer Wilken Abnahmestelle werden können
	Aber deren Nelos sich unterscheiden. Zur sicherheit werden alle Abnahmestellen aus Wilken für diese Treffer ausgewiesen

	-- Das ist eine Prüfliste!

	select * from [mart_technische_doku].[caigos_elektro_nelos_falsch_zugeordnet] order by abnahmestelle_adresse

*/



CREATE view [mart_technische_doku].[caigos_elektro_nelos_falsch_zugeordnet] as

    with abweichungen as (

        select distinct
            wilken_adrabgleich
        from 
            [mart_technische_doku].[caigos_elektro_adressabgleich_abnahmestellen_wilken]
        where
            caigos_adrabgleich = wilken_adrabgleich
            and isnull(caigos_nelo,'') <> ''
            and isnull(wilken_nelo,'') <> ''
            and caigos_nelo <> wilken_nelo
	        and abnahmestelle_status = 1
	        and id_mandant = 1
    )

    select
        * 
    from
        [mart_technische_doku].[caigos_elektro_adressabgleich_abnahmestellen_wilken]
    where
        wilken_adrabgleich in (select wilken_adrabgleich from abweichungen)
        and lokationsbuendel_status = 'aktiv'

		

GO
