-- Object: mart_energieportfoliomanagement.dim_fernwaerme_kundenkategorien
-- Type  : VIEW






/*
	-- Test 

		select top 200 * from [mart_energieportfoliomanagement].[dim_fernwaerme_kundenkategorien] order by [id_kundenkategorie]
		

*/


CREATE view [mart_energieportfoliomanagement].[dim_fernwaerme_kundenkategorien] as

	select distinct
		k.id_kundenkategorie,
		kk.kundenkategorie
	from
		core.kunden k
	join
		core.kundenkategorie kk on k.id_kundenkategorie = kk.id_kundenkategorie and k.id_mandant = kk.id_mandant
	join
		core.link_kunde_zaehlpunkt lkz on k.id_kunde = lkz.id_kunde and k.id_mandant = lkz.id_mandant
	join
		raw.wilken_crgpvertraglink l on lkz.id_link_messeinheit = l.GPVL_FKID
	join
		raw.wilken_crgpvertrag v on l.GPVG_ID = v.GPVG_ID
	join
		raw.wilken_crprodukt p on v.PRD_ID = p.PRD_ID 
	where
		k.id_mandant = 1
		and p.PRD_ENERGIEART = 5
		--and v.GPVG_STATUS <> 0


GO
