-- Object: stage.wilken_zaehlpunkt
-- Type  : VIEW

/*

	change log
	----------
	17.06.2026	OMe	abn_status hinzu
	18.06.2026	OMe	Spannungsebene/Druckstufe und Gasdruck hinzu
	24.06.2026	OMe Lastprofil aus den Bilanzierungsdaten hinzu (letzte Zeitscheibe)
	08.09.2026	OME Meststellenbetreiber letzte Zeitscheibe


	test
	----
	select * from [stage].[wilken_zaehlpunkt] where id_energieart in (1,2)

*/
CREATE view [stage].[wilken_zaehlpunkt] as

	with zpnetz as (

		SELECT  
			[MND_ID]
			,[ZPT_ID]
			,[ZPN_GUELTIGAB]
			,[NET_ID]
			, row_number() over (partition by MND_ID, ZPT_ID order by ZPN_GUELTIGAB DESC) as rang
		FROM 
			[raw].[wilken_enzpn]

	), zpdaten as (

		SELECT  
			[MND_ID]
			,[ZPT_ID]
			,[ZPD_GUELTIGAB]
			,isnull([SPE_NR_ENTNAHME],[SPE_NR_MESSUNG]) as [SPE_NR_ENTNAHME]
			,[SPE_NR_MESSUNG]
			,[ZPD_ANSCHLUSSLEISTUNG]
			,[ZPD_INST_LEISTUNG]
			,ZPD_GASDRUCK
			, row_number() over (partition by MND_ID, ZPT_ID order by ZPD_GUELTIGAB DESC) as rang
		FROM 
			[raw].[wilken_enzptdaten]

	), bilanzierungsdaten as (

		select  
			cast(zpt_id as int) as zpt_id,
			cast(mnd_id as int) as mnd_id,
			isnull(cast(zvf_nr as int),-1) as id_zaehlverfahren,
			isnull(cast(lpr_id as int),-1) as id_lastprofil
			, row_number() over (partition by mnd_id, zpt_id order by zpbd_gueltigab desc) as rang
		from 
			[raw].[wilken_enzpbdaten]	

	), messtellenbetreiber as (

		select 
			cast(zpt_id as int) as zpt_id
			,cast([mbt_id] as int) as id_messstellenbetreiber
			,cast(zmb_grundzustaendig as int) as grundzustaendig_messstellenbetreiber
			,[zmb_gueltigab]
			,[zmb_gueltigbis]
			,row_number() over (partition by zpt_id order by zmb_gueltigab desc) as rang
		from 
			[raw].[wilken_enzptmessstellenbetreiber]
		where
			[zmb_status] = 1

	)
	SELECT 
		ZP.MND_ID as wilken_mnd_id,
		ZP.ZPT_ID AS wilken_zpt_id,
		ZPT_METERINGCODE meteringcode,
		ZPT_ENERGIEART as id_energieart,
		ZPT_TYP as id_zp_typ,
		ABN_STRASSE + ' ' + ISNULL(CAST(ABN_HAUSNR AS VARCHAR),'') + ISNULL(CAST(ABN_HAUSUNTERNR AS VARCHAR),'') + ', ' + CAST(ABN_PLZ AS VARCHAR) + ' ' + ABN_ORT abnahmestelle_adresse,
		ABN_LTO_NR ablesetour_nr,
		ZP.BRW_NR as wilken_brw_nr,
		ZP.ZPT_ISMESSLOKATION as wilken_zpt_ismesslokation,
		ZP.ZPT_KOMPLEXEMESSUNG as wilken_zpt_komplexemessung,
		[ZPT_ANGELEGT] as created_at,
		[ZPT_GEAENDERT] as changed_at,
		ABN_STRASSE as abnahmestelle_straße,
		CAST(ABN_HAUSNR as INT) as abnahmestelle_hausnummer,
		ABN_HAUSUNTERNR as abnahmestelle_hausnummer_zusatz,
		CAST(ABN_PLZ AS VARCHAR(10)) as abnahmestelle_plz,
		ABN_ORT as abnahmestelle_ort,
		cast(ABN.ABN_ID as int) as id_abn,
		isnull(cast(netz.NET_ID as int),0) as id_netz,
		cast(isnull(ABN.ABN_STATUS,-1) as int) as abnahmestelle_status,
		-- 
		isnull(cast([SPE_NR_ENTNAHME] as int),-1) as id_spannungsebene,
		cast([SPE_NR_MESSUNG] as int) as id_spannungsebene_messung,

		cast([ZPD_ANSCHLUSSLEISTUNG] as decimal(12,3)) as anschlussleistung,
		cast([ZPD_INST_LEISTUNG] as decimal(12,3)) as installierte_leistung,
		cast(ZPD_GASDRUCK as int) as gasdruck_mbar,

		--
		isnull(b.id_lastprofil,-1) as id_lastprofil,
		isnull(b.id_zaehlverfahren, -1) as id_zaehlverfahren,

		--
		isnull(mbt.id_messstellenbetreiber,-1) as id_messstellenbetreiber,
		isnull(mbt.grundzustaendig_messstellenbetreiber, -1) as grundzustaendig_messstellenbetreiber

	FROM
		[EnergyDWH].raw.wilken_enzpt ZP
	JOIN
		[raw].[wilken_enabn] ABN ON ZP.ABN_ID = ABN.ABN_ID
	
	left join
		zpnetz netz
	on
		zp.mnd_id = netz.mnd_id 
		and zp.ZPT_ID = netz.ZPT_ID
		and netz.rang = 1

	left join
		zpdaten d
	on
		zp.mnd_id = d.mnd_id 
		and zp.ZPT_ID = d.ZPT_ID
		and d.rang = 1

	left join
		bilanzierungsdaten b
	on
		zp.mnd_id = b.mnd_id 
		and zp.ZPT_ID = b.ZPT_ID
		and b.rang = 1

	left join
		messtellenbetreiber mbt
	on
		zp.ZPT_ID = mbt.ZPT_ID
		and mbt.rang = 1


GO
