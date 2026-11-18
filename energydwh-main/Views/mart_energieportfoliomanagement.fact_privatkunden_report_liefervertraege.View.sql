-- Object: mart_energieportfoliomanagement.fact_privatkunden_report_liefervertraege
-- Type  : VIEW



--select * from [mart_energieportfoliomanagement].[fact_privatkunden_report_liefervertraege] where id_energieart=2 order by stichtag desc


CREATE view [mart_energieportfoliomanagement].[fact_privatkunden_report_liefervertraege] as

	with products as (

		select
			produkt_nummer
			,min(kundengruppe) as kundengruppe
		from
			mart_energieportfoliomanagement.privatkunden_report_definition with (nolock)
		group by
			produkt_nummer	
	)

	select
        v.[stichtag]
      ,v.[geaendert_am]
      ,v.[id_link_messeinheit]
      ,v.[id_mandant]
      ,v.[id_energieart]
      ,v.[energieart]
      ,v.[id_zp]
      ,v.[id_kunde]
      ,v.[id_vertrag]
      ,v.[id_produkt]
      ,v.[id_produktvariante]
      ,v.[id_status_mes]
      ,v.[status_mes]
      ,v.[id_vertragsart_mes]
      ,v.[vertragsart_mes]
      ,v.[meteringcode]
      ,v.[malo]
      ,v.[abnahmestelle_adresse]
      ,v.[netz_nummer]
      ,v.[netz]
      ,v.[kunden_nummer]
      ,v.[id_kundenstatus]
      ,v.[kundenstatus]
      ,v.[einzugsdatum]
      ,v.[auszugsdatum]
      ,v.[vertragsnummer]
      ,v.[id_vertragsstatus]
      ,v.[vertragsstatus]
      ,v.[id_vertragsart]
      ,v.[vertragsart]
      ,v.[belieferung_ab]
      ,v.[belieferung_bis]
      ,v.[vertrag_angelegt_am]
      ,v.[vertragsbindung_bis]
      ,v.[kuendigungsfrist_ablauf]
      ,v.[produkt_nummer]
      ,v.[produkt]
      ,v.[variante_nummer]
      ,v.[variante]
      ,v.[jahresverbrauch]
      ,v.[jahresverbrauch_ht]
      ,v.[jahresverbrauch_nt]
      ,v.[id_turnusrechnung]
		-- handelt es sich um einen vertrag mit definierten produkt ?
		,case when p.produkt_nummer is null then 0 else 1 end as flag_vertragimreport
		,isnull(p.kundengruppe,0) as kundengruppe
	from
		mart_energieportfoliomanagement.privatkunden_report_liefervertraege v

	left join
		products p 
	on
		v.produkt_nummer = p.produkt_nummer


GO
