-- Object: mart_energieportfoliomanagement.aktive_liefervertraege
-- Type  : VIEW
/*

	-- Change Log
	
	21.10.2026	OMe Nur letzte Verbrauchszeitscheibe mitnehmen
	22.10.2026	OMe	Auf materialisierte Tabelle stage.


	-- Test 

		select top 1000 * from [mart_energieportfoliomanagement].[aktive_liefervertraege] where produkt_nummer = '10021'

*/


CREATE view [mart_energieportfoliomanagement].[aktive_liefervertraege] as


    select 
        [id_link_messeinheit]
		,[id_mandant]
		,[id_energieart]
		,[energieart]
		,[id_zp]
		,[id_kunde]
		,[id_vertrag]
		,[id_produkt]
		,[id_produktvariante]
		,[id_status_mes]
		,[status_mes]
		,[id_vertragsart_mes]
		,[vertragsart_mes]
		,[meteringcode]
		,[malo]
		,[abnahmestelle_adresse]
		,[netz_nummer]
		,[netz]
		,[kunden_nummer]
		,[id_kundenstatus]
		,[kundenstatus]
		,[einzugsdatum]
		,[auszugsdatum]
		,[vertragsnummer]
		,[id_vertragsstatus]
		,[vertragsstatus]
		,[id_vertragsart]
		,[vertragsart]
		,[belieferung_ab]
		,[belieferung_bis]
		,[vertrag_angelegt_am]
		,[vertragsbindung_bis]
		,[kuendigungsfrist_ablauf]
		,[produkt_nummer]
		,[produkt]
		,[variante_nummer]
		,[variante]
		,[jahresverbrauch]
		,[jahresverbrauch_ht]
		,[jahresverbrauch_nt]
		,[lastprofil]
		,[lastprofil_edicode]
		,[zaehlverfahren]
		,[zaehlverfahren_edicode]
		,[id_kundengruppe]
		,[id_kundenkategorie]
		,[id_turnusrechnung]
		,[turnusrechnung]
		,[id_lieferant]
		,[id_spannungsebene]
		,[id_energierichtung]
		,[id_netz]
    from 
        [stage].[wilken_aktive_vertraege]


GO
