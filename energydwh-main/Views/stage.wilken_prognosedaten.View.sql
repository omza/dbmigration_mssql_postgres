-- Object: stage.wilken_prognosedaten
-- Type  : VIEW


/*


	Aus der IVU App "Verträge zum Stichtag geklaut"


	test
	----
	select * from [stage].[wilken_prognosedaten] where sequencenr = 1 and jahresverbrauch_nt > 0 order by id_zp

*/
CREATE view [stage].[wilken_prognosedaten] as


	WITH melo_jahresverbraeuche as (
	
		select 
			zpt_id,
			zptem_zeitraumvon, 
			zptem_zeitraumbis, 
			year(zptem_zeitraumbis) abrechnungsjahr,
			DATEDIFF(day,zptem_zeitraumvon, zptem_zeitraumbis) as anzahltage,
			sum(case when zptma_verbrauchber is null then 0 else zptma_verbrauchber end) as zptem_verbrauchber, 
			sum(case when zptma_jahresverbrauchber is null then 0 else zptma_jahresverbrauchber end) as zptem_jahresverbrauchber,
			sum(case 
					when zptma_verbrauchber is null then 0 
					else case 
							when enzptma.vba_nr in('1002','1005','10051') then zptma_verbrauchber 
							else 0 
						end 
				end) as zptem_verbrauchber_nt,

			sum(case 
					when zptma_jahresverbrauchber is null then 0 
					else case 
							when enzptma.vba_nr in('1002','1005','10051') then zptma_jahresverbrauchber 
							else 0 
						end 
				end) as zptem_jahresverbrauchber_nt,

			row_number() over (partition by zpt_id order by zptem_zeitraumbis desc) sequencenr
		from 
			raw.wilken_enzptma enzptma
		join
			raw.wilken_enzptem  enzptem on	enzptma.zptem_id = enzptem.zptem_id
		where 1=1
			and zptem_zeitraumbis >= '01.01.2019'
			and enzptem.zptem_art = 0
			and enzptem.prz_id not in('5')
			and enzptma.vba_nr in(
			'2001',
			'2004',
			'20050',
			'1001',
			'1004',
			'1002',
			'1005',
			'10050',
			'10051')
		group by 
			zpt_id, zptem_zeitraumvon, zptem_zeitraumbis
	)
	select
		zpt_id as id_zp,
		zptem_zeitraumvon as abrechnung_von, 
		zptem_zeitraumbis as abrechnung_bis, 
		abrechnungsjahr,
		anzahltage,
		zptem_verbrauchber as verbrauch,
		zptem_verbrauchber- zptem_verbrauchber_nt as verbrauch_ht,
		zptem_verbrauchber_nt as verbrauch_nt,
		zptem_jahresverbrauchber as jahresverbrauch,
		zptem_jahresverbrauchber-zptem_jahresverbrauchber_nt as jahresverbrauch_ht,
		zptem_jahresverbrauchber_nt as jahresverbrauch_nt,
		sequencenr
	from
		melo_jahresverbraeuche



/*
	with melo_jahresverbraeuche as (
	
		select 
			zpt_id, 
			zeitraum_von, 
			zeitraum_bis, 
			sum(case when zptma_verbrauchber is null then 0 else zptma_verbrauchber end) as verbrauch_abgerechnet_gesamt, 
			sum(case when zptma_jahresverbrauchber is null then 0 else zptma_jahresverbrauchber end) as jahresverbrauch_gesamt, 
			sum(case 
					when zptma_verbrauchber is null then 0 
					else case 
							when enzptma.vba_nr in('1002','1005','10051') then zptma_verbrauchber 
							else 0 
						end 
				end) as zptem_verbrauchber_nt,

			sum(case 
					when zptma_jahresverbrauchber is null then 0 
					else case 
							when enzptma.vba_nr in('1002','1005','10051') then zptma_jahresverbrauchber 
							else 0 
						end 
				end) as zptem_jahresverbrauchber_nt,

			row_number() over (partition by zpt_id order by zptem_zeitraumvon desc) sequencenr



		from 
			raw.wilken_enzptma enzptma
		left join
			raw.wilken_enzptem  enzptem on	enzptma.zptem_id = enzptem.zptem_id
		where
			zptem_zeitraumbis >= '01.01.2019'
			and enzptem.zptem_art = 0
			and enzptem.prz_id not in('5')
			and enzptma.vba_nr in(
			'2001',
			'2004',
			'20050',
			'1001',
			'1004',
			'1002',
			'1005',
			'10050',
			'10051')
		group by 
			zpt_id, zptem_zeitraumvon, zptem_zeitraumbis
	
	
	), 
	
	melo_365_fehltage as (

		select
			zpt_id, 
			zptem_zeitraumvon, 
			zptem_zeitraumbis, 
			zptem_verbrauchber, 
			zptem_jahresverbrauchber, 
			case
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 0 preceding and 0 preceding) between 355 and 375 then 1
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 1 preceding and 0 preceding) between 355 and 375 then 2
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 2 preceding and 0 preceding) between 355 and 375 then 3
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 3 preceding and 0 preceding) between 355 and 375 then 4
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 4 preceding and 0 preceding) between 355 and 375 then 5
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 5 preceding and 0 preceding) between 355 and 375 then 6
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 6 preceding and 0 preceding) between 355 and 375 then 7
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 7 preceding and 0 preceding) between 355 and 375 then 8
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 8 preceding and 0 preceding) between 355 and 375 then 9
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 9 preceding and 0 preceding) between 355 and 375 then 10
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 10 preceding and 0 preceding) between 355 and 375 then 11
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 11 preceding and 0 preceding) between 355 and 375 then 12
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 12 preceding and 0 preceding) between 355 and 375 then 13
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 13 preceding and 0 preceding) between 355 and 375 then 14
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 14 preceding and 0 preceding) between 355 and 375 then 15
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 15 preceding and 0 preceding) between 355 and 375 then 16
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 16 preceding and 0 preceding) between 355 and 375 then 17
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 17 preceding and 0 preceding) between 355 and 375 then 18
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 18 preceding and 0 preceding) between 355 and 375 then 19
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 19 preceding and 0 preceding) between 355 and 375 then 20
				when sum(datediff(day, zptem_zeitraumvon, zptem_zeitraumbis)) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 20 preceding and 0 preceding) between 355 and 375 then 21
			else 99 end - 1 as anzahl_bis_jahresende
		from 
			melo_jahresverbraeuche

	)
	select * from melo_365_fehltage
	
	prognosewerte as (

		select
			zpt_id, 
			zptem_zeitraumvon as prog_beginn, 
			zptem_zeitraumbis as prog_ende, 
			case when anzahl_bis_365 = 99 then 'prog_wert' else 'abr_365' end as prognosedaten_typ,
			 
			case 
				when anzahl_bis_365 = 99 
					then zptem_jahresverbrauchber 
					else sum(zptem_verbrauchber) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between 0 preceding and anzahl_bis_jahresende preceding)  
			end as prognose_summe_365,
			sum(zptem_verbrauchber) over (partition by zpt_id  order by zptem_zeitraumbis asc rows between anzahl_bis_jahresende preceding and 0 preceding) as prognose_abr_365
		from
			[melo_365_fehltage]

	)

	select 
		zpt_id,
		prog_beginn,
		prog_ende,
		case when prognosedaten_typ = 'prog_wert' then prognose_summe_365 else prognose_abr_365 end as jahresprognose
	from 
		prognosewerte
		*/

GO
