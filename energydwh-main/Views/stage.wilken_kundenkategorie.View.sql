-- Object: stage.wilken_kundenkategorie
-- Type  : VIEW








CREATE view [stage].[wilken_kundenkategorie] as

	select
		cast(MND_ID as int) as id_mandant,
		cast(KAT_NR as char(3)) as id_kundenkategorie,
		ltrim(rtrim(left(KAT_BEZEICHNUNG,50))) as kundenkategorie
	from
		raw.wilken_enkategorie 



GO
