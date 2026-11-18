-- Object: mart_energiemanagement.DIM_WILHELMTEL_MESSPUNKTE
-- Type  : VIEW


/*

	Rainer hat eine neue Datenquelle "power_switch" von Frank Schmöller (Wilhelm.tel operations) aufgetan. In dieser lassen sich die Energieverbräuche für die Saga MFGs sowie die Saga IPUeps ableiten.

	Über die POP liste lassen sich Verbräuche aus Wilken ermitteln (so die Theorie ;-))

	Für SAGA MFGs werden stündlich Volt und Ampere aus der Eltek Stromschiene ausgelesen
	Für SAGA IPUEPs liefert die DB für jeden Tag die Arbeit in WATT/h. Dieser Wert ist aber berechnet. Wie? k.A.

	Rainer möchte diese in Qlik auswertbar haben (Gesamtverbrauch in kWh im selektierten Zeitraum und Verlauf je Stunde bzw. Tag)

	Bei der Datenmodellierung würde ich die Fasernetztopologie sowie die Betreibereigenschaft berücksichtigen wollen. D.h. folgende Attribute müssen zu den MFGS/ IPUEPs gespeichert werden

	Betreiber (wilhelm.tel/willy.tel)
	Wohnungsbau SAGA Flag (SAGA ja oder nein) 
	Netzebene (3 und ggf. 4)
	POP Zuordnung (MFG bzw. IPUEPs)

*/


CREATE view [mart_energiemanagement].[DIM_WILHELMTEL_MESSPUNKTE] as


	SELECT 
		mp.[id_messpunkt]
		,mp.[id_mandant]
		,mnd.mandant
		,mp.[id_energieart]
		,ea.energieart
	
		,[id_geraeteart]
		,gart.definition as geraeteart
		,case when [id_geraeteart] = 301 then 3 else 4 end as netzebene
		,case when mp.id_quellsystem = 3 then 'SAGA' else NULL end as Wohnungsbaugesellschaft
		,mp.[id_geraetetyp]
		,gtyp.geraetetyp
		,mp.[id_quellsystem]
		,src.definition as quellsystem
		,[messpunkt_ident]
		,[messpunkt_name]
		,[messpunkt_beschreibung]
		,[location_lat]
		,[location_lon]
		,pop.wert as pop_nr
		,saga.wert as saga_id
	FROM 
		[core].[messpunkte] mp
	join
		core.mandant mnd on mp.id_mandant = mnd.id_mandant
	join
		core.energiearten ea on mp.id_energieart = ea.id_energieart
	join
		core.schluesseldefinition gart on gart.feldname = 'id_geraeteart' and  mp.[id_geraeteart] = gart.wert
	join
		core.geraetetypen gtyp on mp.[id_geraetetyp] = gtyp.id_geraetetyp
	join
		core.schluesseldefinition src on src.feldname = 'id_quellsystem' and  mp.[id_quellsystem] = src.wert
	left join
		core.messpunkt_attribute pop on pop.id_messpunkt_attribut = 1 and mp.id_messpunkt = pop.id_messpunkt
	left join
		core.messpunkt_attribute saga on saga.id_messpunkt_attribut = 2 and mp.id_messpunkt = saga.id_messpunkt
	WHERE
		mp.id_mandant = 2	

	


GO
