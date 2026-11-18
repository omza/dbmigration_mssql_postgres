-- Object: mart_energieportfoliomanagement.fact_privatkunden_report
-- Type  : VIEW







--select * from [mart_energieportfoliomanagement].[fact_privatkunden_report] where [energieart]='Gas' and kundengruppe = 2 order by stichtag desc, sortierung


CREATE view [mart_energieportfoliomanagement].[fact_privatkunden_report] as

/*
	select stichtag
		  ,[energieart]
		  ,[ueberschrift1]
		  ,[ueberschrift2]
		  ,zusammenfassung
		  ,[sortierung]
		  ,[anzahl_abnahmestellen]
		  ,[menge_abnahmestellen_kwh]
		  ,[anzahl_abnahmestellen] - lag([anzahl_abnahmestellen], 1, 0) over (partition by [energieart],[ueberschrift1],[ueberschrift2] order by stichtag) as [anzahl_abnahmestellen_veraenderung_vormonat]
		  ,[menge_abnahmestellen_kwh] - lag([menge_abnahmestellen_kwh], 1, 0) over (partition by [energieart],[ueberschrift1],[ueberschrift2] order by stichtag) as [menge_abnahmestellen_kwh_veraenderung_vormonat]
		  ,ROW_NUMBER() over (partition by sortierung order by stichtag desc) as rang
		  ,[changed_at]
	from 
		[mart_energieportfoliomanagement].[privatkunden_report]
*/


			with abnahmestellen_definition as (
				select 
					stichtag
					,geaendert_am		
					,[id_link_messeinheit]
					,[id_mandant]
					,v. [id_energieart]
					,[energieart]
					,[id_produkt]
					,v.[produkt_nummer]
					,[jahresverbrauch]
					,[jahresverbrauch_ht]
					,[jahresverbrauch_nt]
					---
					,rep.ueberschrift1
					,rep.ueberschrift2
					,rep.zusammenfassung
					,rep.prognosewert
					,rep.sort as sortierung
					,rep.kundengruppe

					,case 
						when jahresverbrauch between kwh_staffel_von and kwh_staffel_bis then 

							case 
								when prognosewert = 'Gesamt' then 1 
								when prognosewert = 'HT' then 1
								when prognosewert = 'NT' then null -- Spezialfall Kunden werden nur bei HT einmal gezählt
								else
									null						
							end				

						else null
					end as anzahl_abnahmestellen
					,case 
						when jahresverbrauch between kwh_staffel_von and kwh_staffel_bis then 
			
							case 
								when prognosewert = 'Gesamt' then cast(round(jahresverbrauch,0) as bigint)
								when prognosewert = 'HT' then cast(round(jahresverbrauch_ht,0) as bigint)
								when prognosewert = 'NT' then cast(round(jahresverbrauch_nt,0) as bigint)
							else
								null
							end
						else null
					end as [menge_abnahmestellen_kwh]

				from 
					[mart_energieportfoliomanagement].privatkunden_report_definition rep
				left join
					[mart_energieportfoliomanagement].[privatkunden_report_liefervertraege] v
					 
				on 
					v.id_energieart = rep.id_energieart
					and v.produkt_nummer = rep.produkt_nummer

			), 
	
			abnahmestellen_zugeordnet as (

				select 
					stichtag
					,geaendert_am
					,[id_link_messeinheit]
					,[id_mandant]
					,[id_energieart]
					,[energieart]
					,[id_produkt]
					,[produkt_nummer]
					,[jahresverbrauch]
					,[jahresverbrauch_ht]
					,[jahresverbrauch_nt]
					,ueberschrift1
					,ueberschrift2
					,zusammenfassung
					,sortierung
					,kundengruppe
					,prognosewert
					,anzahl_abnahmestellen
					,[menge_abnahmestellen_kwh]
				from
					abnahmestellen_definition
				where
					anzahl_abnahmestellen is not null
					or menge_abnahmestellen_kwh is not null


			), gruppiert as (

				select
					stichtag,
					max(geaendert_am) as geaendert_am,
					[energieart],
					kundengruppe,
					[ueberschrift1],
					[ueberschrift2],
					sortierung,
					sum([anzahl_abnahmestellen]) as [anzahl_abnahmestellen],
					sum([menge_abnahmestellen_kwh]) as [menge_abnahmestellen_kwh],
					zusammenfassung
				from
					abnahmestellen_zugeordnet
				group by
					stichtag,
					[energieart],
					kundengruppe,
					[ueberschrift1],
					[ueberschrift2],
					sortierung,
					zusammenfassung
			)
			select 
				stichtag
				,[energieart]
				,kundengruppe
				,[ueberschrift1]
				,[ueberschrift2]
				,zusammenfassung
				,[sortierung]
				,[anzahl_abnahmestellen]
				,[menge_abnahmestellen_kwh]
				,[anzahl_abnahmestellen] - lag([anzahl_abnahmestellen], 1, 0) over (partition by [energieart],[ueberschrift1],[ueberschrift2] order by stichtag) as [anzahl_abnahmestellen_veraenderung_vormonat]
				,[menge_abnahmestellen_kwh] - lag([menge_abnahmestellen_kwh], 1, 0) over (partition by [energieart],[ueberschrift1],[ueberschrift2] order by stichtag) as [menge_abnahmestellen_kwh_veraenderung_vormonat]
				,ROW_NUMBER() over (partition by [energieart], kundengruppe, sortierung order by stichtag desc) as rang
				,geaendert_am 
			from
				gruppiert

GO
