-- Object: stage.wilken_technische_ressourcen
-- Type  : VIEW



/*===============================================================

selectiert aus den technischen Ressourcen von Wilken die relevanten Informationen für die weitere Verarbeitung in der DWH-Umgebung.


change history
27.05.2026 | OME | Initial creation
11.06.2026	OMe	id_abn mitnehmen
17.06.2926	OMe	abnahmestellen status abfragen (nur aktive Abnahmestellen brücksichtigen)
13.07.2026	OMe	TRE_ID als Wilken_ID hinzufügen 
23.09.2026	OMe Fix technische Ressoursen werden nicht mitgenommen ids 35821,41169
19.10.2026	OMe	Fix doublette technische Ressource - nr

test
select * from [stage].[wilken_technische_ressourcen] 
where id_wilken_ressource in (35821,41169)
order by abnahmestelle_ort, abnahmestelle_strasse, abnahmestelle_hausnummer, abnahmestelle_hausnummer_zusatz

*/
CREATE view [stage].[wilken_technische_ressourcen] as

	-- Zugriffsweg über technische Ressourcen

	with adressen as (

		select 
			[id_abn]
			,[abnahmestelle_status]
			,[id_mandant]
			,[abnahmestelle_adresse]
			,[abnahmestelle_straße]
			,[abnahmestelle_hausnummer]
			,[abnahmestelle_hausnummer_zusatz]
			,[abnahmestelle_plz]
			,[abnahmestelle_ort]
			,[ablesetour_nr]
			,[created_at]
			,[changed_at]
		from 
			[stage].[wilken_abnahmestellen]

	),

	nelo as (

		select
			id_mandant,
			id_abn,
			id_netzlokation,
			netzlokation
		from
			core.lokationsbuendel
		where 
			netzlokation is not null
		group by
			id_mandant,
			id_abn,
			id_netzlokation,
			netzlokation
		having
			count(distinct id_abn) = 1
	
	),

	malo as (

		SELECT 
			[TRE_ID] as id_tre
			,max(case when [TRMA_LIEFERRICHTUNG] = 1 then tre.MLK_ID else null end) as id_malo_bezug
			,max(case when [TRMA_LIEFERRICHTUNG] = 1 then mlk.MLK_CODE else null end) as malo_bezug
			,max(case when [TRMA_LIEFERRICHTUNG] = 2 then tre.MLK_ID else null end) as id_malo_einspeisung
			,max(case when [TRMA_LIEFERRICHTUNG] = 2 then mlk.MLK_CODE else null end) as malo_einspeisung
			,min(cast([TRMA_GUELTIGAB] as date)) as gueltig_ab
			,max(isnull(cast([TRMA_GUELTIGBIS] as date), '9999-12-31')) as gueltig_bis
		FROM 
			[raw].[wilken_entremarktlokation] tre

		join
			raw.wilken_enmlk mlk 
		on 
			tre.MLK_ID = mlk.MLK_ID

		group by
			[TRE_ID]

	),

	trezp as (

		select
			row_number() over (partition by TRE_ID order by isnull(TRME_GEAENDERT,TRME_ANGELEGT) desc) as rang
			,*
		from
			raw.wilken_entremesslokation
		where
			getdate() between TRME_GUELTIGAB and isnull(TRME_GUELTIGBIS,getdate())	

	)

	select distinct
		cast(tre.MND_ID as int) as id_mandant,
		cast(tre.ABN_ID as int) as id_abn,
		adr.abnahmestelle_straße,
		isnull(adr.abnahmestelle_hausnummer,-1) as abnahmestelle_hausnummer,
		isnull(adr.abnahmestelle_hausnummer_zusatz,'') as abnahmestelle_hausnummer_zusatz,
		adr.abnahmestelle_plz,
		adr.abnahmestelle_ort,
		adr.abnahmestelle_status,
	
		-- nelo
		isnull(nelo.netzlokation,'-') as nelo,
		--nelo.nelo_zusatz,

		-- melo
		cast(trezp.ZPT_ID as int) as id_zp,
		isnull(zp.meteringcode,'-') melo,

		-- malo
		malo.id_malo_bezug,
		malo.malo_bezug,
		malo.id_malo_einspeisung,
		malo.malo_einspeisung,

		-- Technische Ressource
		tre.TRE_ID as id_wilken_ressource,
		tre.TRE_TR_ID as id_ressource,

		-- Ressourcendaten
		case
			when tred.trd_artnutzung = 0 then 'Verbrauch'
			when tred.trd_artnutzung = 1 then 'Erzeugung'
			when tred.trd_artnutzung = 2 then 'Speicher'
			else null 
		end as ressource_nutzungsart,

		case when tre.TRE_BEMERKUNG <> tre.TRE_TR_ID then tre.TRE_BEMERKUNG else null end ressource_bemerkung,

		case
			when tred.TRD_ERZEUGUNGSART = 0 then 'Solar'
			when tred.TRD_ERZEUGUNGSART = 1 then 'Wind'
			when tred.TRD_ERZEUGUNGSART = 2 then 'Gas'
			when tred.TRD_ERZEUGUNGSART = 3 then 'Wasser'
			when tred.TRD_ERZEUGUNGSART = 4 then 'Sonstige'
			else null 
		end as ressource_erzeugungsart,
		/*case
			when tred.TRD_SPEICHERART = 0 then 'Wasserstoffspeicher'
			when tred.TRD_SPEICHERART = 1 then 'Pumpspeicher'
			when tred.TRD_SPEICHERART = 2 then 'Batteriespeicher'
			when tred.TRD_SPEICHERART = 3 then 'Sonstiger Speicher'
			else null 
		end as ressource_speicherart,*/
		tred.TRD_NENNLEISTUNG_ABGABE nennleistung_kw_abgabe,
		tred.TRD_NENNLEISTUNG_AUFNAHME nennleistung_kw_aufnahme,
		tred.TRD_SPEICHERKAPAZITAET as speicherkapazitaet_kwh,
		svba.SVBA_BEZEICHNUNG stromverbrauchsart,
		waen.WAEN_BEZEICHNUNG waermenutzung,

		tred.trd_verbr_res_is_enwg as faellt_unter_enwg14a,
		tred.trd_verbr_res_inbetriebsetzung as inbetriebnahme_nach_2023,
		case 
			when tred.trd_verbr_res_einordnung = 1 then 'Wechsel einmalig noch möglich'
			when tred.trd_verbr_res_einordnung = 2 then 'Wechsel nicht möglich'
			when tred.trd_verbr_res_einordnung = 3 then 'Wechsel bis 2028 nicht möglich'
			when tred.trd_verbr_res_einordnung = 4 then 'Wechsel durchgeführt'
			else null 
		end as einordnung_enwg_vor2024,
		tred.trd_weitere_tech_einrichtungen as weitere_technische_einrichtungen,

		cast(tre.TRE_BEGINN as date) ressource_gueltig_ab,
		cast(tre.TRE_ENDE as date) ressource_gueltig_bis,

		cast(tre.TRE_ANGELEGT as date) as created_at,
		cast(isnull(tre.TRE_GEAENDERT,tre.TRE_ANGELEGT) as date) as changed_at

	from
		[raw].[wilken_entechnischeressource] as tre

	left join
		adressen as adr	on tre.ABN_ID = adr.id_abn

	join
		raw.wilken_entredaten as tred on tre.TRE_ID = tred.TRE_ID

	left join
		raw.wilken_ensvba svba on tred.SVBA_NR = svba.SVBA_NR

	left join
		raw.wilken_edwaen waen on tred.WAEN_NR = waen.WAEN_NR

	left join
		 trezp 
	on 
		tre.TRE_ID = trezp.TRE_ID
		and rang = 1

	left join
		core.zaehlpunkte zp on trezp.ZPT_ID = zp.id_zp

	left join
		nelo on tre.ABN_ID = nelo.id_abn
		--and getdate() between nelo.nelo_gueltig_ab and nelo.nelo_gueltig_bis 

	left join
		malo on tre.TRE_ID = malo.id_tre
		and getdate() between malo.gueltig_ab and malo.gueltig_bis


	where
		getdate() between tre.TRE_BEGINN and isnull(tre.TRE_ENDE,getdate())
		and tred.TRD_GUELTIGAB <= getdate()
	 



GO
