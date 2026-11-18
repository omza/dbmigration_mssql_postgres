-- Object: mart_energiemanagement.FACT_MESSPUNKTE_VERBRAUCH
-- Type  : VIEW





/*

DIM ZEIT

*/


CREATE view [mart_energiemanagement].[FACT_MESSPUNKTE_VERBRAUCH] as


		select
			CAST(Convert(CHAR(8),tag,112) as bigint) as '%KEYDATE'
			,[tag] as Datum
			,id_messpunkt
			,11190 [id_obis]
			,[id_version]
			,[tagesverbrauch_kWh] as 'kWh'
			,[messeinheit]
			,[wertstatus_gesamt] as id_wertstatus
			  ,[0]
			  ,[1]
			  ,[2]
			  ,[3]
			  ,[4]
			  ,[5]
			  ,[6]
			  ,[7]
			  ,[8]
			  ,[9]
			  ,[10]
			  ,[11]
			  ,[12]
			  ,[13]
			  ,[14]
			  ,[15]
			  ,[16]
			  ,[17]
			  ,[18]
			  ,[19]
			  ,[20]
			  ,[21]
			  ,[22]
			  ,[23]
			  ,[b_stunde] as '2b'
		from
			core.messwerte_lastgang_60min
		where
			id_obis in (11160, 11190)


	UNION
		select
			CAST(Convert(CHAR(8),tag,112) as bigint) as '%KEYDATE'
			,[tag] as Datum
			,id_messpunkt
			,11190 [id_obis]
			,[id_version]
			,[tagesverbrauch_kWh] as 'kWh'
			,[messeinheit]
			,[id_wertstatus]
			  ,[Wert] as [0]
			  ,NULL [1]
			  ,Null [2]
			  ,Null [3]
			  ,Null [4]
			  ,Null [5]
			  ,Null [6]
			  ,Null [7]
			  ,Null [8]
			  ,Null [9]
			  ,Null [10]
			  ,Null [11]
			  ,Null [12]
			  ,Null [13]
			  ,Null [14]
			  ,Null [15]
			  ,Null [16]
			  ,Null [17]
			  ,Null [18]
			  ,Null [19]
			  ,Null [20]
			  ,Null [21]
			  ,Null [22]
			  ,Null [23]
			  ,Null as '2b'
		from
			core.messwerte_tag
		where
			id_obis in (11160, 11190)




GO
