-- Object: stage.caigos_gas_hausanschluesse
-- Type  : VIEW






/*
	ermittelt aus der raw tabellen die caigos gas hausanschlüsse

	19.02.2026	OMe	Initial
	25.02.2026	OMe	Datumkonvertierung

	select * from [stage].[caigos_gas_hausanschluesse]

*/
CREATE view [stage].[caigos_gas_hausanschluesse] as

	select 
		[mha_id]

		,nobj.mno_bez as netzobjekt
		,nobj.mno_nr as netzobjekt_nr


		,[mha_status] as status
		,[mha_schadenvorh] as schaden_vorhanden

		,[mha_druckstufe] as druckstufe
		,[mha_druckebene] as druckebene

		,strasse.msr_name as strasse
	
		,case 
			when charindex('-',[mha_hnr]) > 0 then UPPER(LTRIM(RTRIM([mha_hnr])))
			else stage.numeric_value_from_string([mha_hnr])
		end as hausnummer

		,CASE 
			WHEN stage.alphanumeric_value_from_string([mha_hnr]) IN ('','-') then ltrim(rtrim([mha_uhausnr]))
			ELSE LTRIM(RTRIM(UPPER(stage.alphanumeric_value_from_string([mha_hnr]))))
		END as hausnummer_zusatz
		
		,[mha_hnr] as hausnummer_original
		,[mha_uhausnr] as hausnummer_zusatz_original

		,strasse.msr_ort as ort

		,[mha_auftragnr] as wilken_csp_auftrag
		-- ,[mha_ausbetdatum]
		-- ,[mha_auszugssich]
		--,[mha_baukosten]
		--,[mha_baukostzu]
		,[mha_bemerkung1] as bemerkung
		,[mha_bemerkung2] as bemerkung2
		,[mha_besonderheit] as besonderheit


		--,[mha_bez]
		--,[mha_beznr]
		-- ,[mha_datestampedit]
		-- ,[mha_datestampnew]
		--,[mha_druckb]
		--,[mha_druckn]
		--,[mha_druckp]

		-- ,[mha_energieart]
		--,[mha_fremdkey]
		-- ,[mha_gebschl]
		--,[mha_heklaenge]
		,case when year([mha_installdatum]) = 1777 then null else cast([mha_installdatum] as date) end as installationsdatum
		,case when year([mha_einbdat]) = 1777 then null else cast([mha_einbdat] as date) end as einbaudatum

		,[mha_herstjahr] as herstellungsjahr

		, mst.mme_bez as meister_bezeichnung
		, mst.mme_nr as meister_nr

		,[mha_natiefbau] as tiefbau
		,[mha_nrtiefbau] as tiefbau_nr

		,[mha_mauerdurch] as mauerdurchbruch
		,[mha_userfld1]
		,[mha_userfld2]
		,[mha_userfld3]
		,[mha_userfld4]
		,[mha_userfld5]
		,[mha_userfld6]
		,[mha_userfld7]
		,[mha_userfld8]

		,[mha_lage] as lageinfo
		,[mha_feldbuchnr] as feldbuchnummer

		,[mha_hochwert] as geo_hochwert
		,[mha_rechtswert] as geo_rechtswert
		,[mha_zwert] as geo_hoehe

	from 
		[raw].[caigos_gas_mhausan] mha
	join
		raw.caigos_gas_mmeister mst on mha.mha_idmmeister = mst.mme_id
	join
		raw.caigos_gas_mnetzobj nobj on mha.mha_idmnetzobj = nobj.mno_id
	join
		raw.caigos_gas_mstrasse strasse on mha.mha_idmstrasse = strasse.msr_id

GO
