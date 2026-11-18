-- Object: stage.argos_file_kopf_tmp
-- Type  : VIEW





CREATE view [stage].[argos_file_kopf_tmp] as


		select 
			piv.load_log_id, 
			piv.filename, 
			LTRIM(RTRIM([Kunde:]))	AS Kunden_Name, 
			LTRIM(RTRIM([Kundennummer:])) AS Kunden_Nummer, 
			LTRIM(RTRIM([Zählpunktbez.:])) as Meteringcode, 
			LTRIM(RTRIM([MessgeräteNr:])) AS Zaehlernummer, 
			CAST([Kanal:] AS INT) AS Kanal, 
			LTRIM(RTRIM([OBIS-Kennzahl:])) as OBIS, 
			CONVERT(date,[Zeitraum:],104) AS Zeitraum,
			cal.tag,
			cal.[id_typtag],
			cal.[id_zeitumstellung],
			CAST([Faktor:] as INT) as Wandlerfaktor , 
			CAST([Meßperiode:] as Int)/60 as Raster_Minuten, 
			LTRIM(RTRIM([Einheit:])) Messeinheit, 
			CAST([Daten:] as INT) Anzahl_Werte, 
			CAST(REPLACE([Energie:],',','.') as DECIMAL(18,3)) as kWh
		from
			(
			  select 
				filename, load_log_id, last, Zeit
			  from [raw].[argos_lastgang_tmp]
			) d
			pivot
			(
			  max(last)
			  for Zeit in ([Kunde:], [Kundennummer:], [Zählpunktbez.:], [MessgeräteNr:], [Kanal:], [OBIS-Kennzahl:], [Zeitraum:], [Faktor:], [Meßperiode:], [Einheit:], [Daten:], [Energie:])
			) piv
		join
			(select distinct tag, id_typtag, id_zeitumstellung from core.kalender) cal on CONVERT(date,[Zeitraum:],104) = cal.tag

GO
