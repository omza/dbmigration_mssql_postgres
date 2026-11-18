-- Object: dbo.IVU_STAGE_View
-- Type  : VIEW
  create view IVU_STAGE_View as
  SELECT  distinct z.id, [ZaehlerNummer]
      ,[OBIS]
      
  FROM [EnergyDWH].[dbo].[ivu_stage] i
  left join zaehlpunkte z on i.Messlokation = z.zaehlpunktbezeichnung
GO
