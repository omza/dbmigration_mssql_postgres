-- Object: stage.wilken_zaehlpunkt_bilanzierung
-- Type  : VIEW




/*


	Bilanzierungsdaten je Zählpunkt aus Bilanzierungszeitscheiben


	test
	----
	select * from [stage].[wilken_zaehlpunkt_bilanzierung]  order by id_zp, gueltig_ab

*/
CREATE view [stage].[wilken_zaehlpunkt_bilanzierung] as

	select 
		cast(zpt_id as int) as id_zp
		,cast(mnd_id as int) as id_mandant

		,cast(zpbd_gueltigab as date) as gueltig_ab

		,case 
			when lag(zpbd_gueltigab,1,0) over (partition by [zpt_id] order by zpbd_gueltigab desc, zpbd_id) = convert(date, '01.01.1900', 104) 
				then convert(date, '31.12.9999',104)
			else
				cast(lag(zpbd_gueltigab ,1,0) over (partition by [zpt_id] order by zpbd_gueltigab desc, zpbd_id) as date)
			end
		as gueltig_bis	  
		,isnull(cast(zvf_nr as int),-1) as id_zaehlverfahren
		,isnull(cast(lpr_id as int),-1) as id_lastprofil
		,cast(zpbd_jahresentnahme as decimal(16,3)) as jahresentnahme_kwh
		,cast(isnull(big_id,-1) as int) as id_bilanzierungsgebiet
		,cast(case 
			when [ZPBD_MESSTECHN_EINORDN_MALO] = 0 then 'KME/mME'
			when [ZPBD_MESSTECHN_EINORDN_MALO] = 1 then 'IMS'
			when [ZPBD_MESSTECHN_EINORDN_MALO] = 2 then 'Kein Messung'
			else 'unbekannt'
		end as varchar(15)) as messtechnik_malo
		,isnull(cast(PRGG_NR as int),-1) as id_prognosegrundlage

		--
		,cast(ZPBD_ANGELEGT as datetime) as created_at
		,cast(isnull(ZPBD_GEAENDERT, ZPBD_ANGELEGT) as datetime) as changed_at
	from 
		raw.wilken_enzpbdaten
	where 
		zpbd_jahresentnahme > 0


GO
