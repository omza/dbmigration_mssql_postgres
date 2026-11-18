-- Object: dbo.ARGOS_STAGE_View
-- Type  : VIEW

  CREATE view ARGOS_STAGE_View as
  select distinct  zaehlpunktbezeichnung,kunde, kundennummer,  messgeraetenummer, faktor, messperiode, einheit
    FROM [EnergyDWH].[dbo].[ARGOS_STAGE]
GO
