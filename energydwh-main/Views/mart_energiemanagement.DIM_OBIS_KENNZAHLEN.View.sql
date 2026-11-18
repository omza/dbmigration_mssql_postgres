-- Object: mart_energiemanagement.DIM_OBIS_KENNZAHLEN
-- Type  : VIEW




/*

DIM ZEIT

*/


CREATE view [mart_energiemanagement].[DIM_OBIS_KENNZAHLEN] as


	SELECT 
		[id_obis]
		  ,[obis_kennziffer]
		  ,[obis_einheit]
		  ,[obis_beschreibung]
		  ,[id_energieart]
		  ,[obis_energierichtung]
	  FROM 
		[core].[obis]


GO
