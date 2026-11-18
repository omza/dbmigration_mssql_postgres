-- Object: stage.wilken_jahresentnahmen
-- Type  : VIEW



/*


	Jahresentnahmen je Messeinheit aus Bilanzierungszeitscheiben


	test
	----
	select * from [stage].[wilken_jahresentnahmen] where rang = 1  order by id_link_messeinheit

*/
CREATE view [stage].[wilken_jahresentnahmen] as

	select 
		  row_number() over (partition by mes_id order by mje_gueltigab desc, mje_id) as rang
		  ,[mes_id] as id_link_messeinheit
		  ,cast([mje_gueltigab] as date) as gueltig_ab

	,case 
			when lag([mje_gueltigab],1,0) over (partition by mes_id order by mje_gueltigab desc, mje_id) = convert(date, '01.01.1900', 104) 
				then convert(date, '31.12.9999',104)
			else
				cast(lag([mje_gueltigab] ,1,0) over (partition by mes_id order by mje_gueltigab desc, mje_id) as date)
			end
		  as gueltig_bis	  

		  ,[mje_jahresentnahme] as jahresverbrauch
	  from 
		[energydwh].[raw].[wilken_enmesjahresentnahme]
	where 
		mje_stammdatenaenderung = 1


GO
