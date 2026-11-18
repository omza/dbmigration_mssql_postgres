-- Object: stage.privatkunden_report_definition
-- Type  : VIEW




/*
	change log:

	24.03.2026	OMe	Zusammenfassung (Regelsatz) hinzufügen
	01.06.2026	OMe	Definition für Gas ergänzt
	09.06.2026	OMe	Geschäftskunden Report definition hinzufügen
	10.06.2026	OMe	Erhöhung der staffel bis werte auf 999.999.999 kwH   weil wir im Strom Geschäftskunden bereich großverbraucher hatten


	test: select * from [stage].[privatkunden_report_definition]

*/
CREATE view [stage].[privatkunden_report_definition] as


	-- Privatkundenreport Strom
	SELECT 
		1 as id_energieart
		,cast(ltrim(rtrim(Produktnummer)) as varchar(10)) as produkt_nummer
		,try_cast(ltrim(rtrim([Sort])) as int) as sort
		,cast(ltrim(rtrim([Überschrift1])) as varchar(100)) as ueberschrift1
		,cast(ltrim(rtrim([Überschrift2])) as varchar(100)) as ueberschrift2
		,ltrim(rtrim(replace(Zusammenfassung, '0' , ''))) zusammenfassung 
		,cast(ltrim(rtrim([Prognosewert])) as varchar(20)) as prognosewert
		,isnull(try_cast([Staffel_Von] as int),0) as kwh_staffel_von
		,cast(case  
			when try_cast([Staffel_Bis] as int) = 0 then 999999999
			when try_cast([Staffel_Bis] as int) is null then 999999999
			else [Staffel_Bis]
		end as int) as kwh_staffel_bis
		,1 as kundengruppe
	FROM 
		[raw].[privatkundenreport_strom_definition]
	where
		isnull([Überschrift1],'') <> ''
		and isnull(Prognosewert,'') <> ''


	union

	-- Privatkundenreport Gas
	SELECT 
		2 as id_energieart
		,cast(ltrim(rtrim(Produktnummer)) as varchar(10)) as produkt_nummer
		,try_cast(ltrim(rtrim([Sort])) as int) as sort
		,cast(ltrim(rtrim([Überschrift1])) as varchar(100)) as ueberschrift1
		,cast(ltrim(rtrim([Überschrift2])) as varchar(100)) as ueberschrift2
		,ltrim(rtrim(replace(Zusammenfassung, '0' , ''))) zusammenfassung 
		,cast(ltrim(rtrim([Prognosewert])) as varchar(20)) as prognosewert
		,isnull(try_cast([Staffel_Von] as int),0) as kwh_staffel_von
		,cast(case  
			when try_cast([Staffel_Bis] as int) = 0 then 999999999
			when try_cast([Staffel_Bis] as int) is null then 999999999
			else [Staffel_Bis]
		end as int) as kwh_staffel_bis
		,1 as kundengruppe
	FROM 
		[raw].[privatkundenreport_gas_definition]
	where
		isnull([Überschrift1],'') <> ''
		and isnull(Prognosewert,'') <> ''

	union

	-- Geschäftskundenreport Gas
	SELECT 
		2 as id_energieart
		,cast(ltrim(rtrim(Produktnummer)) as varchar(10)) as produkt_nummer
		,try_cast(ltrim(rtrim([Sort])) as int) as sort
		,cast(ltrim(rtrim([Überschrift1])) as varchar(100)) as ueberschrift1
		,cast(ltrim(rtrim([Überschrift2])) as varchar(100)) as ueberschrift2
		,ltrim(rtrim(replace(Zusammenfassung, '0' , ''))) zusammenfassung 
		,cast(ltrim(rtrim([Prognosewert])) as varchar(20)) as prognosewert
		,isnull(try_cast([Staffel_Von] as int),0) as kwh_staffel_von
		,cast(case  
			when try_cast([Staffel_Bis] as int) = 0 then 999999999
			when try_cast([Staffel_Bis] as int) is null then 999999999
			else [Staffel_Bis]
		end as int) as kwh_staffel_bis
		,2 as kundengruppe
	FROM 
		[raw].[gkkundenreport_gas_definition]
	where
		isnull([Überschrift1],'') <> ''
		and isnull(Prognosewert,'') <> ''

	union

	-- Geschäftskundenreport Strom
	SELECT 
		1 as id_energieart
		,cast(ltrim(rtrim(Produktnummer)) as varchar(10)) as produkt_nummer
		,try_cast(ltrim(rtrim([Sort])) as int) as sort
		,cast(ltrim(rtrim([Überschrift1])) as varchar(100)) as ueberschrift1
		,cast(ltrim(rtrim([Überschrift2])) as varchar(100)) as ueberschrift2
		,ltrim(rtrim(replace(Zusammenfassung, '0' , ''))) zusammenfassung 
		,cast(ltrim(rtrim([Prognosewert])) as varchar(20)) as prognosewert
		,isnull(try_cast([Staffel_Von] as int),0) as kwh_staffel_von
		,cast(case  
			when try_cast([Staffel_Bis] as int) = 0 then 999999999
			when try_cast([Staffel_Bis] as int) is null then 999999999
			else [Staffel_Bis]
		end as int) as kwh_staffel_bis
		,2 as kundengruppe
	FROM 
		[raw].[gkkundenreport_strom_definition]
	where
		isnull([Überschrift1],'') <> ''
		and isnull(Prognosewert,'') <> ''


GO
