-- Object: stage.wilken_ablesetouren
-- Type  : VIEW









CREATE view [stage].[wilken_ablesetouren] as

	select 
		cast([mnd_id] as int) as id_mandant
		,cast([LTO_NR] as int) as id_ablesetour
		,cast(rtrim(ltrim(replace([lto_bezeichnung],cast([LTO_NR] as varchar),''))) as varchar(100)) as ablesetour
		,cast([LTO_SONDERTOUR] as int) as sondertour


	from 
		raw.wilken_enlauftour




GO
