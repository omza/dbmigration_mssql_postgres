-- Object: stage.wilken_kundengruppen
-- Type  : VIEW








CREATE view [stage].[wilken_kundengruppen] as

	select
		cast(MND_ID as int) as id_mandant,
		cast(KNG_ID as int) as id_kundengruppe,
		ltrim(rtrim(left(KNG_BEZEICHNUNG,50))) as kundengruppe,
		try_cast(KNG_ANGELEGT as datetime) as created_at,
		try_cast(isnull(KNG_GEAENDERT, KNG_ANGELEGT)  as datetime) as changed_at
	from
		raw.wilken_enkng 



GO
