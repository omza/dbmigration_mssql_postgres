-- Object: mart_energievertrieb.lastgang_rlmkunden_strom_werte
-- Type  : VIEW



/*
	
	Werte für den Lastgangversand an Kunden durch Energievertrieb
	Ansprechpartner Nicola Lindhorst, Michelle Jaß und Sonja von Prossel



	-- Test 

		select Zeit,Last,bstunde from [mart_energievertrieb].[lastgang_rlmkunden_strom_werte] 
		where 
			id_messpunkt = 1865
			and jahr = 2025
			and monat = 10
		order by
			tag,
			stunde,
			bstunde,
			minuten

*/


CREATE view [mart_energievertrieb].[lastgang_rlmkunden_strom_werte] as

	select
		MONTH(tag) as monat
		,YEAR(tag) as jahr
		,id_messpunkt
		,messung_am
		,convert(varchar(10), messung_am, 104) + ' ' + left(right(convert(varchar, dateadd(minute,15,messung_am), 20),8),5) + ' ' + bstunde as Zeit
		-- In der Tabelle Messwerte ist der Zeitstempel "messung_am" immer der Anfang einer 1/4 Std.
		,messwert as [Last]
		,tag
		,DATEPART(hour,messung_am) Stunde
		,DATEPART(minute,messung_am) Minuten
		,bstunde
	from
		core.messwerte with (nolock)
	where
		id_obis in (111290) -- Wirkenergie Lastgang Strom Bezug
		and messeinheit = 'kW'
		and bstunde in ('', 'b')
		--and id_messpunkt = 1865
		--and YEAR(tag) = 2025
		--and MONTH(tag) = 10
	--order by messung_am

GO
