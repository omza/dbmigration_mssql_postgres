-- Object: stage.wilken_produkte
-- Type  : VIEW


/*

	change log
	----------
	26.02.2026	OMe Initial
	
	test
	----
	select *  from [stage].[wilken_produkte] order by gueltig_von, id_produkt, id_produktvariante

*/

CREATE view [stage].[wilken_produkte] as

	select 
		  [prd_id] as id_produkt
		  ,0 as id_produktvariante
		  ,[prd_energieart] as id_energieart
		  ,[prd_art] as id_produktart
		  /*
				1: Abrechnungsprodukt
				2: Portalprodukt
				3: E-Mobilityprodukt
				4: Vertragsschablone
				5: Fremdprodukt
				6: Telekommunikationsprodukt
				7: Kartenabrechnung
				8: Portfolioabrechnungsprodukt
				10: NN
				11: Sperrkosten
				20: ESM
				25:	Nebenkostenabrechnungsprodukt
				30: Provision
				35: Mehr-/Mindermenge
				36: MMM-Weiterleitung (Vertrieb)
				37: MMM-Beschaffungsprodukt
				40: Gebührensatzung
		  */
		  ,[prd_produktnr] as produkt_nummer
		  ,[prd_bezeichnung] as produkt
		  ,[prd_publikationsbezeichnung] as produkt_publikationsbezeichnung

		 ,null as variante_nummer
		  ,null as variante
		  ,null as variante_publikationsbezeichnung

		  ,cast(isnull([prd_gueltigvon],convert(date,'01.01.1970',104)) as date) as gueltig_von
		  ,cast(isnull([prd_gueltigbis],convert(date,'31.12.9999',104) ) as date) as gueltig_bis

		  ,[prd_status] as produkt_status
		 ,null as variante_status

		  ,[prd_angelegt] as created_at
		  ,isnull([prd_geaendert],[prd_angelegt]) as changed_at
    
	  from 
		[raw].[wilken_crprodukt]

	union

	select 

		  p.[prd_id] as id_produkt
		  ,[prdv_id] as id_produktvariante
		  ,[prd_energieart] as id_energieart
		  ,[prd_art] as id_produktart

		  ,[prd_produktnr] as produkt_nummer
		  ,[prd_bezeichnung] as produkt
		  ,[prd_publikationsbezeichnung] as produkt_publikationsbezeichnung

		 ,[prdv_nr] as variante_nummer
		  ,[prdv_bezeichnung] as variante

		  ,[prdv_pubbezeichnung] as variante_publikationsbezeichnung

		  ,cast(isnull([prd_gueltigvon],convert(date,'01.01.1970',104)) as date) as gueltig_von
		  ,cast(isnull([prd_gueltigbis],convert(date,'31.12.9999',104) ) as date) as gueltig_bis

		  ,[prd_status] as produkt_status
		 ,[prdv_status] as variante_status


		  ,[prdv_angelegt] as created_at
		  ,isnull([prdv_geaendert],[prdv_angelegt]) as changed_at

	  from 
		[raw].[wilken_crproduktvarianten] v
	join
		[raw].[wilken_crprodukt] p on v.prd_id = p.prd_id


GO
