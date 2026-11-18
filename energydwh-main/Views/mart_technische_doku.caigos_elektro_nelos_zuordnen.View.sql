-- Object: mart_technische_doku.caigos_elektro_nelos_zuordnen
-- Type  : VIEW

/*

    Nelo Schnittstelle per Adressabgleich mit Wilken Abnahmestellen verbinden
    Diese Abfrage liefert alle Caigos ehas, die per adressabgleich zugeordnet werden können
	Allerdings auch die, die Prüffälle sind, in erster linie mehrere Hausanschlüsse an einer Adresse in Caigos

	select * from [mart_technische_doku].[caigos_elektro_nelos_zuordnen] order by abnahmestelle_adresse

*/



CREATE view [mart_technische_doku].[caigos_elektro_nelos_zuordnen] as

	with doubletten_wilken as (

		select
			wilken_adrabgleich
		from
			[mart_technische_doku].[caigos_elektro_adressabgleich_abnahmestellen_wilken]
		group by
			wilken_adrabgleich
		having
			count(distinct id_abn) = 1
			and count(distinct wilken_nelo) = 1

	),

	leere_ehas as (

		select
			caigos_adrabgleich
		from
			[mart_technische_doku].[caigos_elektro_adressabgleich_abnahmestellen_wilken]
		where
			isnull(caigos_nelo,'') = ''
			and isnull(caigos_adrabgleich,';;;') <> ';;;'
		group by
			caigos_adrabgleich

	),

	wilken_nelo_schon_vergeben as (

		select distinct
			w.wilken_nelo
			,case when c.caigos_nelo is null then 0 else 1 end nelo_bereits_vergeben
		from
			[mart_technische_doku].[caigos_elektro_adressabgleich_abnahmestellen_wilken] w
		left join
			[mart_technische_doku].[caigos_elektro_adressabgleich_abnahmestellen_wilken] c on w.wilken_nelo = c.caigos_nelo
		where
			isnull(w.wilken_nelo,'') <> ''

	),

	caigos_ehas_an_adresse as (

		select
			caigos_adrabgleich
			,count(distinct eha_id) as anzahl_eha
		from
			[mart_technische_doku].[caigos_elektro_adressabgleich_abnahmestellen_wilken]
		where
			isnull(caigos_adrabgleich,';;;') <> ';;;'
		group by
			caigos_adrabgleich


	)
	select distinct
		[eha_id]
      ,[eha_nr]
      ,[eha_bez]
      ,[status]
      ,[strasse]
      ,[hausnummer_original] as hausnummer
      ,[hausnummer_zusatz_original] as hnr_zusatz
      ,[plz]
      ,[ort]
      ,[versorgungsbezirk]
      ,[anschlussort]
      ,[lageinfo]
      ,[caigos_nelo]
      ,liste.[wilken_nelo]
      ,[abnahmestelle_adresse]
      ,[anzahl_melos]
	  ,flag_vergeben.nelo_bereits_vergeben
	  ,ehas.anzahl_eha as anzahl_hausanschluesse_an_adresse
	from
		[mart_technische_doku].[caigos_elektro_adressabgleich_abnahmestellen_wilken] liste
	
	join
		wilken_nelo_schon_vergeben flag_vergeben on liste.wilken_nelo = flag_vergeben.wilken_nelo

	join
		caigos_ehas_an_adresse ehas on liste.caigos_adrabgleich = ehas.caigos_adrabgleich

	where
		eha_id is not null
		and id_abn is not null
		
		
		and abnahmestelle_status = 1
		and id_mandant = 1
		and liste.caigos_adrabgleich in (
			select caigos_adrabgleich from leere_ehas
		)
		and liste.wilken_adrabgleich in (
			select wilken_adrabgleich from doubletten_wilken
		)

		

GO
