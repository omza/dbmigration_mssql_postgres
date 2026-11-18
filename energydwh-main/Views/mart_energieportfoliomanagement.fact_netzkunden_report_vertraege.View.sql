-- Object: mart_energieportfoliomanagement.fact_netzkunden_report_vertraege
-- Type  : VIEW



--select * from [mart_energieportfoliomanagement].[fact_netzkunden_report_vertraege] where id_energieart=2 order by stichtag desc


CREATE view [mart_energieportfoliomanagement].[fact_netzkunden_report_vertraege] as

	with nsnd as (

		select distinct
			id_mandant,
			id_spannungsebene,
			id_energieart,
			spannungsebene
		from
			core.spannungsebenen
		where 
			id_mandant = 1
			and edicode in ('','Y03','E06', 'Z19')


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
		,v.[lastprofil]
		,v.[lastprofil_edicode]
		,v.[zaehlverfahren]
		,v.[zaehlverfahren_edicode]
		,v.[id_kundengruppe]
		,v.[id_kundenkategorie]
		,v.[id_lieferant]
		,v.[id_spannungsebene]
		,v.[id_energierichtung]
		,v.[id_netz]
		,v.[id_turnusrechnung]
	
		,sp.spannungsebene
		,kg.kundengruppe
		,kk.kundenkategorie

		,lief.lieferant
		,lief.eic_nummer

		-- Haushalt nach Reportdefinition = 1 sonst 0
		,case 
			
			when lower(produkt) not like '%rlm%' -- keine rlm produkte
					and (
						lastprofil_edicode in ('HSH','NO0') -- hsh Profil 
						or jahresverbrauch < 10000 -- oder unter 10.000
					) then 1
			else 0

		end	as report_kundengruppe

	from
		[mart_energieportfoliomanagement].[kunden_report_netzvertraege] v
	
	-- Nur Nieder- spannungs bzw. druck Abnahmestellen zählen
	join 
		nsnd sp on v.id_mandant = sp.id_mandant and v.id_spannungsebene = sp.id_spannungsebene

	left join
		core.kundengruppen kg on kg.id_mandant = v.id_mandant and kg.id_kundengruppe = v.id_kundengruppe

	left join
		core.kundenkategorie kk on kk.id_mandant = v.id_mandant and kk.id_kundenkategorie = v.id_kundenkategorie

	left join
		core.lieferanten lief 
	on 
		lief.id_mandant = v.id_mandant 
		and lief.id_energieart = v.id_energieart 
		and lief.id_lieferant = v.id_lieferant 


	where
		v.id_mandant = 1


GO
