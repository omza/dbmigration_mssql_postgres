-- Object: mart_energiemanagement.FACT_RECHENZENTRUM_VERBRAUCH
-- Type  : VIEW


CREATE view [mart_energiemanagement].[FACT_RECHENZENTRUM_VERBRAUCH] as


	select 
		p.[messpunkt_name]
		,p.messpunkt_ident
		--,t.geraetetyp
		,tag as '%KEY_DATE'
		,w.messung_am
		,o.obis_kennziffer
		--,obis_beschreibung
		,w.messwert
		,w.messeinheit
	from 
		core.messwerte w 
	join 
		core.messpunkte p on w.id_messpunkt = p.id_messpunkt 
	join
		core.obis o on w.id_obis = o.id_obis
	left join
		core.geraetetypen t on p.id_geraetetyp = t.id_geraetetyp and p.id_energieart = t.id_energieart 
	where 
		p.id_quellsystem = 5


GO
