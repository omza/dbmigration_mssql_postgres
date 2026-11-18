-- Object: mart_technische_doku.caigos_nelos_technische_ressourcen_wilken
-- Type  : VIEW





/*
	select * from [mart_technische_doku].[caigos_nelos_technische_ressourcen_wilken] order by geaendert_am desc, delta, nelo desc, id_ressource desc

*/



CREATE view [mart_technische_doku].[caigos_nelos_technische_ressourcen_wilken] as

    select 

        [delta]
        ,[erstellt_am]
        ,[geaendert_am]
        ,[geloescht_am]
        ,pflegehinweis

        ,[abnahmestelle_straße]
        ,[abnahmestelle_hausnummer]
        ,[abnahmestelle_hausnummer_zusatz]
        ,[abnahmestelle_plz]
        ,[abnahmestelle_ort]
        ,[nelo]
        ,[melo]
        ,[malo_bezug]
        ,[malo_einspeisung]
        ,[id_ressource]
        ,[ressource_nutzungsart]
        ,[ressource_bemerkung]
        ,[ressource_erzeugungsart]
        ,[nennleistung_kw_abgabe]
        ,[nennleistung_kw_aufnahme]
        ,[speicherkapazitaet_kwh]
        ,[stromverbrauchsart]
        ,[waermenutzung]
        ,[faellt_unter_enwg14a]
        ,[inbetriebnahme_nach_2023]
        ,[einordnung_enwg_vor2024]
        ,[weitere_technische_einrichtungen]
        ,[ressource_gueltig_ab]
        ,[ressource_gueltig_bis]

        ,wilken.eha_id
        ,eha.strasse
        ,eha.hausnummer_original
        ,eha.hausnummer_zusatz_original
        ,eha.ort

    from 
        [mart_technische_doku].[caigos_technische_ressourcen_wilken] wilken

    left join
        stage.caigos_elektro_hausanschluesse eha on wilken.eha_id = eha.eha_id

    union

    select 
        [delta]
        ,[erstellt_am]
        ,[geaendert_am]
        ,[geloescht_am]
        ,pflegehinweis
        ,[abnahmestelle_straße]
        ,[abnahmestelle_hausnummer]
        ,[abnahmestelle_hausnummer_zusatz]
        ,[abnahmestelle_plz]
        ,[abnahmestelle_ort]
        ,[nelo]
        ,'-' [melo]
        ,null [malo_bezug]
        ,null [malo_einspeisung]
        ,null [id_ressource]
        ,null [ressource_nutzungsart]
        ,null [ressource_bemerkung]
        ,null [ressource_erzeugungsart]
        ,null [nennleistung_kw_abgabe]
        ,null [nennleistung_kw_aufnahme]
        ,null [speicherkapazitaet_kwh]
        ,null [stromverbrauchsart]
        ,null [waermenutzung]
        ,null [faellt_unter_enwg14a]
        ,null [inbetriebnahme_nach_2023]
        ,null [einordnung_enwg_vor2024]
        ,null [weitere_technische_einrichtungen]
        ,null [ressource_gueltig_ab]
        ,null [ressource_gueltig_bis]

        ,wilken.eha_id
        ,eha.strasse
        ,eha.hausnummer_original
        ,eha.hausnummer_zusatz_original
        ,eha.ort

    from 
        [mart_technische_doku].caigos_nelos_wilken wilken

    left join
        stage.caigos_elektro_hausanschluesse eha on wilken.eha_id = eha.eha_id

		

GO
