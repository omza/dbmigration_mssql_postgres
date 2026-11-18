-- Object: stage.wilken_marktlokationen
-- Type  : VIEW







CREATE view [stage].[wilken_marktlokationen] as


	with letze_malo as (

		SELECT 
			row_number() over (partition  by mlk.[MLK_ID], ISNULL(Z.ZMLK_GUELTIGAB,convert(date,'01.01.1900',104)) order by ISNULL(Z.ZMLK_GUELTIGBIS,convert(date,'31.12.9999',104)) desc ) row#
			  ,mlk.[MLK_ID] as wilken_mlk_id
			  ,[MND_ID] as wilken_mnd_id
			  ,Z.ZPT_ID as wilken_zpt_id
			  ,[MLK_CODE] as malo

			  ,Z.ZMLK_ID as wilken_zmlk_id
			,Z.ZMLK_TYP as wilken_zmlk_typ -- 1= Entnahme, 2 = Einspeisung
			  ,[MLK_ERSTMALIGE_KOMMUNIKATION] erste_mako
			  ,[MLK_ANGELEGT] as created_at
			  ,[MLK_GEAENDERT] as changed_at

			,ISNULL(Z.ZMLK_GUELTIGAB,convert(date,'01.01.1900',104)) as valid_from
			,ISNULL(Z.ZMLK_GUELTIGBIS,convert(date,'31.12.9999',104)) as valid_to
			--,CASE WHEN Z.ZMLK_GUELTIGBIS is null then 1 ELSE 0 END active
			,row_number() over (partition  by mlk.[MLK_CODE] order by ISNULL([MLK_GEAENDERT],[MLK_ANGELEGT]) desc, ISNULL(Z.ZMLK_GUELTIGAB,convert(date,'01.01.1900',104)) desc) letzte_row_je_malo
		FROM 
			[raw].[wilken_enmlk] mlk
		join
			raw.wilken_enzptmlk z on mlk.MLK_ID = Z.MLK_ID
	)
	SELECT
		wilken_mlk_id
		,wilken_mnd_id
		,wilken_zpt_id
		,malo

		,wilken_zmlk_id
		,wilken_zmlk_typ -- 1= Entnahme, 2 = Einspeisung
		,erste_mako
		,created_at
		,changed_at

		,valid_from
		,valid_to
		,case
			when cast(valid_to as date) = '9999-12-31' then 1
			else case 
					when letzte_row_je_malo = 1 then 1 
					else 0 
				 end
		end active
					
	FROM	
		letze_malo
	WHERE
		row# = 1
		and valid_from < valid_to


GO
