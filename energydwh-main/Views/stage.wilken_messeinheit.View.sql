-- Object: stage.wilken_messeinheit
-- Type  : VIEW



CREATE view [stage].[wilken_messeinheit] as


	SELECT
		cast(MES_ID as int) id_link_messeinheit
		,cast([MND_ID] as int) id_mandant
		,cast([ZPT_ID] as int) id_zp
		,cast([KND_ID] as int) id_kunde

		,cast([MES_EINBAUDATUM] as date) as valid_from
		,cast(isnull([MES_AUSBAUDATUM],'9999-12-31') as date) as valid_to
		,cast(MES_STATUS as int) as id_status 
		,case MES_STATUS
			when 0 then 'Inaktiv'
			when 1 then 'Aktiv'
			when 2 then 'Abzurechnen'
			when 3 then 'Zum Einzug vorbereitet'
			when 4 then 'Geplant'
			when 8 then 'Storniert, Bilanzierungsrelevant'
			when 9 then 'Storniert'
			
			else 'unbekannt'
		end as status
		,cast([LIF_ID] as int) as id_lieferant
		,cast([MES_WANDLERFAKTOR] as decimal(10,3)) as wandlerfaktor
		,cast([MES_VERTRAGSART] as int) as id_vertragsart
		,case [MES_VERTRAGSART]
			when 1 then 'Liefervertrag'
			when 2 then 'Netznutzungsvertrag'
			when 3 then 'MSB-Vertrag'
			when 5 then 'Anschlussnutzungsvertrag'
			when 6 then 'Einspeisevertrag'
			when 7 then 'Blindarbeitsrechnung'
			when 8 then 'MSB iMS-Vertrag'
			else 'unbekannt'
		end as vertragsart
		,cast([MES_JAHRESVERBRAUCH] as DECIMAL(15,3)) as jahresverbrauch
		,cast ([MES_ANGELEGT] as date) as created_at
		,cast ([MES_GEAENDERT] as date) as changed_at
		,case when MES_AUSBAUDATUM is null and MES_STATUS = 1 then 1 else 0 end as active
	FROM 
		[raw].[wilken_enmes]


GO
