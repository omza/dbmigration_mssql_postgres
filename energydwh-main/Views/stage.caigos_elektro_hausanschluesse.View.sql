-- Object: stage.caigos_elektro_hausanschluesse
-- Type  : VIEW







/*
	ermittelt aus der raw tabellen die caigos elektro hausanschlüsse

	28.05.2026	OMe	Initial
	11.06.2026	OMe	eha_nr und esr_plz hinzu
	26.08.2026	OMe	Nelo hinzu
	03.09.2026	OMe	Trommelnummer hinzu
	22.09.2026	OMe	eindeutige Trommelnummern nach Prio selektieren

	select * from [stage].[caigos_elektro_hausanschluesse]

*/
CREATE view [stage].[caigos_elektro_hausanschluesse] as

	with eha_trommelnummer_prio as (

		select distinct
			case
				when eh_tabkn1 = 'ehausan' then eh_idkn1
				else eh_idkn2
			end eha_id
			,eh_trommelnr
			,case
				when eh_tabkn1 = 'ehausan' then 1
				else 2
			end prio
		from 
			[raw].[caigos_elektro_ehaab]
		where
			isnull(eh_trommelnr,'') <> '' 
			and (
				eh_tabkn1 = 'ehausan'
				or eh_tabkn2 = 'ehausan')

	),

	eha_trommelnummer as (

		select
			*
			,row_number() over (partition by eha_id order by prio) as rang
		from
			eha_trommelnummer_prio

	)

	select 
		eha.[eha_id]
		,eha_nr as eha_nr
		,nobj.eno_bez as netzobjekt
		,nobj.eno_nr as netzobjekt_nr


		,[eha_status] as status
		,[eha_schadenvorh] as schaden_vorhanden

		,[eha_sicherungstyp] as sicherungstyp
		--,eha_sicherungsgroesse as sicherungsgroesse
		,[eha_anschlleistung] as anschlussleistung


		,strasse.esr_name as strasse
	
		,case 
			when charindex('-',[eha_hnr]) > 0 then UPPER(LTRIM(RTRIM([eha_hnr])))
			else stage.numeric_value_from_string([eha_hnr])
		end as hausnummer

		,CASE 
			WHEN stage.alphanumeric_value_from_string([eha_hnr]) IN ('','-') then ltrim(rtrim([eha_uhausnr]))
			ELSE LTRIM(RTRIM(UPPER(stage.alphanumeric_value_from_string([eha_hnr]))))
		END as hausnummer_zusatz
		
		,[eha_hnr] as hausnummer_original
		,[eha_uhausnr] as hausnummer_zusatz_original

		,strasse.esr_plz as plz
		,strasse.esr_ort as ort
		
		,eha_versorgungsbezirk as versorgungsbezirk
		,eha_anschlort as anschlussort

		,[eha_auftragnr] as auftragsnummer
		-- ,[eha_ausbetdatum]
		-- ,[eha_auszugssich]
		--,[eha_baukosten]
		--,[eha_baukostzu]
		,[eha_bemerkung1] as bemerkung
		,[eha_bemerkung2] as bemerkung2
		--,[eha_besonderheit] as besonderheit


		,[eha_bez]
		,[eha_beznr]
		-- ,[eha_datestampedit]
		-- ,[eha_datestampnew]
		--,[eha_druckb]
		--,[eha_druckn]
		--,[eha_druckp]

		-- ,[eha_energieart]
		--,[eha_fremdkey]
		-- ,[eha_gebschl]
		--,[eha_heklaenge]
		,case when year([eha_installdatum]) = 1777 then null else cast([eha_installdatum] as date) end as installationsdatum
		,case when year([eha_letztekontrolle]) = 1777 then null else cast([eha_letztekontrolle] as date) end as letzte_kontrolle

		,[eha_herstjahr] as herstellungsjahr

		, mst.eme_bez as meister_bezeichnung
		, mst.eme_nr as meister_nr

		,[eha_natiefbau] as tiefbau
		,[eha_nrtiefbau] as tiefbau_nr

		,[eha_hauseinfuehrung] as hauseinfuehrung
		,espa.ens_bez as kabelart
		/*
		,[eha_userfld1]
		,[eha_userfld2]
		,[eha_userfld3]
		,[eha_userfld4]
		,[eha_userfld5]
		,[eha_userfld6]
		,[eha_userfld7]
		*/

		,[eha_lage] as lageinfo
		,[eha_feldbuchnr] as feldbuchnummer

		,[eha_hochwert] as geo_hochwert
		,[eha_rechtswert] as geo_rechtswert
		,[eha_zwert] as geo_hoehe

		--
		,[eha_neloid] as netzlokation
		
		--
		,nvp.eh_trommelnr as nvp_trommelnr

	from 
		[raw].[caigos_elektro_ehausan] eha

	join
		raw.caigos_elektro_emeister mst on eha.eha_idemeister = mst.eme_id

	join
		raw.caigos_elektro_enetzobj nobj on eha.eha_idenetzobj = nobj.eno_id

	join
		raw.caigos_elektro_estrasse strasse on eha.eha_idestrasse = strasse.esr_id

	join
		[raw].[caigos_elektro_enetzspa] espa on eha.eha_idenetzspa = espa.ens_id

	left join 
		eha_trommelnummer nvp 
	on 
		eha.eha_id = nvp.eha_id 
		and rang = 1
		and nvp.eha_id <> '{00000000-0000-0000-0000-000000000000}' 

GO
