-- Object: mart_energievertrieb.dim_zeit
-- Type  : VIEW




/*

DIM ZEIT

*/


CREATE view [mart_energievertrieb].[dim_zeit] as


	select distinct
		isodate as '%KEYDATE'
		,tag as Datum
		,wochentag.definition as Wochentag
		,typtag.definition as Typtag
		,zu.definition as Zeitumstellung
		,YEAR(tag) as Jahr
		,MONTH(tag) as Monat
		,'Q'+cast(quartal as VARCHAR(1)) as Quartal
	from
		core.kalender cal
	join
		core.schluesseldefinition wochentag on wochentag.feldname = 'id_wochentag' and cal.id_wochentag = cast(wochentag.wert as int)
	join
		core.schluesseldefinition typtag on typtag.feldname = 'id_typtag' and cal.id_typtag = cast(typtag.wert as int)
	join
		core.schluesseldefinition zu on zu.feldname = 'id_zeitumstellung' and cal.id_zeitumstellung = cast(zu.wert as int)
	where
		isodate between 20250101 and 20301231 


GO
