-- Object: mart_energievertrieb.dim_rlmkunden_lastgangversand
-- Type  : VIEW






/*
	
	dimension für den Lastgangversand an Kunden durch Energievertrieb
	Ansprechpartner Nicola Lindhorst, Michelle Jaß und Sonja von Prossel



	-- Test 

		select * from [mart_energievertrieb].[dim_rlmkunden_lastgangversand] 

		

*/


CREATE view [mart_energievertrieb].[dim_rlmkunden_lastgangversand] as

	
	select
		ea.energieart,
		zp.zaehlpunkt meteringcode,
		zp.tagvon,
		zp.tagbis
	from
		[raw].[gkenergie_lastgangversand_zaehlpunkte] zp
	join
		core.energiearten ea on zp.id_energieart = ea.id_energieart


	


GO
