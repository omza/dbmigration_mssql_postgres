-- Object: mart_energiemanagement.wtg_glasfaser_abrechnungsmengen
-- Type  : VIEW








/*

	-- Abrechnungsmengen faserinfrastruktur



	-- Test 

		select top 200 * from [mart_energiemanagement].[wtg_glasfaser_abrechnungsmengen] 
		

*/


CREATE view [mart_energiemanagement].[wtg_glasfaser_abrechnungsmengen] as


	with wtg_messeinheiten as (

		select distinct id_link_messeinheit from [mart_energiemanagement].[wtg_glasfaser_netzinfrastruktur]
		
	)
	select 
		cast(enknv.KNV_ID as bigint) as id_abrechnungszeitscheibe,
		CAST(enknv.MES_ID as int) as [id_link_messeinheit],
		isnull(cast(enknv.PRD_ID as int),0) id_produkt,
		cast(enknv.knv_beginn as date) as abrechnung_beginn,
		cast(enknv.knv_ende as date) as abrechnung_ende,
		YEAR(enknv.knv_ende) jahr,
		enknv.vba_nr id_verbrauchsart,
		enprz.prz_id as id_prozess,
		enprz.PRZ_BEZEICHNUNG as prozess,
		cast(enknv.knv_verbrauchber as decimal(10,2)) as abrechnungsmenge,
		envba.vba_einheit as einheit,
		case when cast(enknv.PRD_ID as int) in (14541, 14532, 14512) then 1 else 0 end abgerechnet_eigenverbrauch
	from
		raw.wilken_enkndverbrauch enknv
	join
		raw.wilken_envba envba on enknv.VBA_NR = envba.VBA_NR and enknv.MND_ID = envba.MND_ID
	join
		wtg_messeinheiten wtg on wtg.id_link_messeinheit = CAST(enknv.MES_ID as int)
	left join
		raw.wilken_enprozess enprz on enknv.PRZ_ID = enprz.PRZ_ID and enknv.MND_ID = enprz.MND_ID
	--left join
		--core.link_kunde_zaehlpunkt lkz on lkz.id_mandant = enknv.MND_ID and lkz.id_link_messeinheit = enknv.MES_ID
	WHERE 
		enknv.KNV_STATISTIKRELEVANT = '1'
		AND enknv.KNV_ENERGIEART = '1'
		AND isnull(enprz.PRZ_PROFORMA, 0) <> '1'
		AND enknv.MND_ID = '1'



GO
