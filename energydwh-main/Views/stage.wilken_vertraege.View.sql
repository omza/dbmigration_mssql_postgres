-- Object: stage.wilken_vertraege
-- Type  : VIEW









/*
	ermittelt aus der raw tabellen die Verträge

	18.02.2026	OMe	Initial
	26.02.2026	OMe	id_energieart hinzu um mit enmes eindeutig zu werden

	select * from [stage].[wilken_vertraege]

*/
CREATE view [stage].[wilken_vertraege] as

	with vertraege_roh as (

		select 
			enmes.MND_ID as id_mandant,
			enmes.mes_id as [id_link_messeinheit],	
		
			crgpvg.gpvg_id as id_vertrag,
			crgpvg.GPVG_VERTRAGSNUMMER as vertragsnummer,
			[gpvg_art] as id_vertragsart,
			crgpvg.GPVG_BEGINN as vertragsbeginn,
			--crgpvg.gpvg_abwabrbeginn as ,
			isnull(crgpvg.gpvg_ende,convert(date,'31.12.9999',104)) as vertragsende,
			crgpvg.gpvg_vertragsbindungbis as vertragsbindung_bis,
			crgpvg.gpvg_status as id_vertragsstatus,
			--crgpvg.gpvg_unterzeichnung,
			crgpvg.gpvg_kuendigungzum as vertrag_gekuendigt_zum,
	
			crgpvg.prd_id as id_produkt,
			isnull(crgpvg.prdv_id,0) as id_produktvariante,
			prd.PRD_ENERGIEART as id_energieart,

			crgpvg.gpvg_grundversorgung as grundversorgung,
			crgpvg.gpvg_bestelldatum bestelldatum,
			crgpvg.gpvg_ablaufkuendigungfrist kuendigungsfrist_ablauf,
			--crgpvl.gpvl_fkid,
			case 
				when crgpvg.gpvg_abwabrbeginn is not null and crgpvg.gpvg_abwabrbeginn < enmes.mes_einbaudatum then enmes.mes_einbaudatum
				when crgpvg.gpvg_abwabrbeginn is not null and crgpvg.gpvg_abwabrbeginn < enknd.knd_einzugdatum then enknd.knd_einzugdatum
				when crgpvg.gpvg_abwabrbeginn is null and crgpvg.gpvg_beginn < enmes.mes_einbaudatum then enmes.mes_einbaudatum 
				when crgpvg.gpvg_abwabrbeginn is null and crgpvg.gpvg_beginn < enknd.knd_einzugdatum then enknd.knd_einzugdatum
				when crgpvg.gpvg_abwabrbeginn is not null then crgpvg.gpvg_abwabrbeginn 
				else crgpvg.gpvg_beginn 
			end as belieferung_ab,
			case 
				when crgpvg.gpvg_ende is not null and enmes.mes_ausbaudatum < crgpvg.gpvg_ende then enmes.mes_ausbaudatum
				when crgpvg.gpvg_ende is not null and enknd.knd_auszugdatum < crgpvg.gpvg_ende then enknd.knd_auszugdatum
				when crgpvg.gpvg_ende is not null then crgpvg.gpvg_ende
				when enmes.mes_ausbaudatum is not null then enmes.mes_ausbaudatum
				else convert(date,'31.12.9999',104) 
			end as belieferung_bis,

			crgpvg.gpvg_angelegt as created_at,
			isnull(crgpvg.gpvg_geaendert,crgpvg.gpvg_angelegt) as changed_at
		from 
			[raw].[wilken_crgpvertraglink] crgpvl

		join
			[raw].[wilken_crgpvertrag] crgpvg on crgpvg.gpvg_id = crgpvl.gpvg_id

		join
			[raw].[wilken_enmes] enmes on  crgpvl.gpvl_fkid = enmes.mes_id
	
		join
			[raw].[wilken_enknd] enknd on enmes.knd_id = enknd.knd_id

		join
			raw.wilken_crprodukt prd on crgpvg.PRD_ID = prd.PRD_ID
/*
		where 
			crgpvg.gpvg_status not in(7, 8, 9)
			and enmes.mes_status not in(7, 8, 9)
			and enknd.knd_status not in(7, 8, 9)
*/
		)
	SELECT 
		[id_vertrag]
		,[id_mandant]
		,[id_energieart]
		,[vertragsnummer]
		,[id_vertragsart]
		,[vertragsbeginn]
		,[vertragsende]
		,[vertragsbindung_bis]
		,[id_vertragsstatus]
		,[vertrag_gekuendigt_zum]
		,[id_produkt]
		,[id_produktvariante]
		,[grundversorgung]
		,[kuendigungsfrist_ablauf]
		,min([belieferung_ab]) as [belieferung_ab]
		,max([belieferung_bis]) as [belieferung_bis]
		,[created_at]
		,[changed_at]
	from
		vertraege_roh
	group by
		[id_vertrag]
		,[id_mandant]
		,[id_energieart]
		,[vertragsnummer]
		,[id_vertragsart]
		,[vertragsbeginn]
		,[vertragsende]
		,[vertragsbindung_bis]
		,[id_vertragsstatus]
		,[vertrag_gekuendigt_zum]
		,[id_produkt]
		,[id_produktvariante]
		,[grundversorgung]
		,[kuendigungsfrist_ablauf]
		,[created_at]
		,[changed_at]

GO
