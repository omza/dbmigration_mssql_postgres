-- Object: stage.argos_file_werte
-- Type  : VIEW


CREATE view [stage].[argos_file_werte] as


	--31.01.25 HH:MM
	with werte_raw as (

		select
			id,
			filename,
			lag(Zeit,1, CASE WHEN right(zeit,2) = '15' then left(Zeit,12)+'00' when right(zeit,5) = '07:00' then left(zeit,9) + '06:00' else null end) over (partition by filename order by id) as StartZeit,
			Zeit as zeit,
			try_convert(date,left(Zeit,8),4) as tag,
			--try_convert(datetime,left(Zeit,8),4) + try_convert(datetime,replace(right(Zeit,5)+':00','24','00'),8) as messung_am,
			--DATETIMEFROMPARTS ( SUBSTRING ( Zeit , 7 , 2 ) , SUBSTRING ( Zeit , 4 , 2 ) , left(Zeit,2) , SUBSTRING ( Zeit , 10, 2 ) , right(Zeit,2) , 0 , 0 ) as messung_am,
			try_cast(replace(last,',','.') as decimal(15,3)) as messwert,
			try_cast(Status as int) as argos_wertstatus,
			LTRIM(RTRIM([Status_Text])) as [wertstatus]
		from
			raw.argos_lastgang
		where
			Status_Text is not null
			and isnumeric(Status) = 1
	
	), werte_stage as (

		select
			id,
			filename,
			w.tag,
			zeit,
			try_convert(datetime,left(Zeit,8),4) + try_convert(datetime,replace(right(StartZeit,5)+':00','24','00'),8) as messung_am,
			messwert,
			argos_wertstatus,
			wertstatus,
			id_typtag
		from 
			werte_raw w
		left join
			(select distinct tag, id_typtag from core.kalender with (nolock)) c on w.tag = c.tag
	)
	select
		id,
		filename,
		tag,
		zeit,
		messung_am,
		messwert,
		argos_wertstatus,
		wertstatus,
		id_typtag,
		row_number() over (partition by filename, messung_am order by id) as wert_reihenfolge
	from
		werte_stage
	--order by filename, Zeit


GO
