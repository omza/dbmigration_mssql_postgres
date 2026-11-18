-- Object: core.load_link_kunde_zaehlpunkt
-- Type  : SQL_STORED_PROCEDURE



/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		core.link_kunde_zaehlpunkt
	

-- Change Log

	30.06.2025	OME initial
	23.02.2026	OME importiere nur bekannte zählpunkt
	27.02.2026	OMe	Füge id_vertrag zur core.vertraege hinzu
	


-- Test:

	exec core.[load_link_kunde_zaehlpunkt] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_link_kunde_zaehlpunkt]
	@transform_job_id bigint,
	@verbose tinyint = 0
AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Get SP Name
	DECLARE @SP_NAME varchar(100);
	SELECT @SP_NAME = OBJECT_NAME(@@PROCID);

	IF @verbose = 1 -- Exec Log Detail with SP Name
		INSERT INTO [admin].[transform_log_detail] ([transform_job_id],[transform_routine],[transform_message])
		VALUES (@transform_job_id, @SP_NAME, 'Start')
	

	BEGIN TRY
	--	---------------------------------------------------

	;WITH TargetRows AS 
	(
		----- ZIEL -----

		SELECT 
			id_link_messeinheit
			,[id_mandant]
			,[id_zp]
			,[id_kunde]
			,[valid_from]
			,[valid_to]
			,[id_status]
			,[status]
			,[id_lieferant]
			,[wandlerfaktor]
			,[id_vertragsart]
			,[vertragsart]
			,[jahresverbrauch]
			,[created_at]
			,[changed_at]
			,[active]
			-- 27.02.2026
			,id_vertrag
			,CHECKSUM(
				[id_mandant]
				,[id_zp]
				,[id_kunde]
				,[valid_from]
				,[valid_to]
				,[id_status]
				,[status]
				,[id_lieferant]
				,[wandlerfaktor]
				,[id_vertragsart]
				,[vertragsart]
				,[jahresverbrauch]
				,[created_at]
				,[changed_at]
				,[active]
				,id_vertrag
			) AS CHECKSUM
		FROM 
			[core].[link_kunde_zaehlpunkt]

		AS	Dim


	), vertraege as (

		select 
			prd.PRD_ENERGIEART as id_energieart,
			crgpvl.gpvl_fkid as [id_link_messeinheit],	
		
			crgpvg.gpvg_id as id_vertrag,

			crgpvg.GPVG_BEGINN as vertragsbeginn,
			isnull(crgpvg.gpvg_ende,convert(date,'31.12.9999',104)) as vertragsende,
			crgpvg.gpvg_angelegt as created_at,
			row_number() over (partition by crgpvl.gpvl_fkid, prd.PRD_ENERGIEART order by crgpvg.GPVG_BEGINN desc, crgpvg.gpvg_angelegt desc) as rang
		from 
			[raw].[wilken_crgpvertraglink] crgpvl

		join
			[raw].[wilken_crgpvertrag] crgpvg on crgpvg.gpvg_id = crgpvl.gpvg_id


		join
			raw.wilken_crprodukt prd on crgpvg.PRD_ID = prd.PRD_ID

		where 
			crgpvg.gpvg_status not in(7, 8, 9)
			and getdate() between crgpvg.GPVG_BEGINN and dateadd(day,1,isnull(crgpvg.gpvg_ende,getdate()))


	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		select  
			stg.id_link_messeinheit
			,stg.[id_mandant]
			,stg.[id_zp]
			,[id_kunde]
			,[valid_from]
			,[valid_to]
			,[id_status]
			,[status]
			,[id_lieferant]
			,[wandlerfaktor]
			,[id_vertragsart]
			,[vertragsart]
			,[jahresverbrauch]
			,stg.[created_at]
			,stg.[changed_at]
			,[active]
			,isnull(id_vertrag,0) as id_vertrag

			,CHECKSUM(
				stg.[id_mandant]
				,stg.[id_zp]
				,[id_kunde]
				,[valid_from]
				,[valid_to]
				,[id_status]
				,[status]
				,[id_lieferant]
				,[wandlerfaktor]
				,[id_vertragsart]
				,[vertragsart]
				,[jahresverbrauch]
				,stg.[created_at]
				,stg.[changed_at]
				,[active]
				,isnull(id_vertrag,0)
			) AS CHECKSUM
		from 
			[stage].[wilken_messeinheit] stg
		
		join
			core.zaehlpunkte zp on stg.id_zp = zp.id_zp
		
		left join
			vertraege v 
		on 
			stg.id_link_messeinheit = v.id_link_messeinheit 
			and zp.id_energieart = v.id_energieart 
			and v.rang = 1


		----- QUELLE -----
	)
	AS 
		Source	
	ON	 
		Source.id_link_messeinheit = Target.id_link_messeinheit 

	WHEN MATCHED AND Source.CHECKSUM != Target.CHECKSUM THEN

		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 
				Target.changed_at	=	Source.changed_at
			,	Target.[created_at]	=	Source.[created_at]
			,	Target.[valid_to]	=	Source.[valid_to]

			,	Target.[id_status]	=	Source.[id_status]
			,	Target.[status]	=	Source.[status]

			,	Target.[id_lieferant]	=	Source.[id_lieferant]
			,	Target.[wandlerfaktor]	=	Source.[wandlerfaktor]

			,	Target.[id_vertragsart]	=	Source.[id_vertragsart]
			,	Target.[vertragsart]	=	Source.[vertragsart]

			,	Target.[jahresverbrauch]	=	Source.[jahresverbrauch]

			,	Target.active	=	Source.active

			,	Target.[id_mandant]	=	Source.[id_mandant]
			,	Target.[id_zp]	=	Source.[id_zp]

			,	Target.[id_kunde]	=	Source.[id_kunde]
			,	Target.[valid_from]	=	Source.[valid_from]
			-- 27.02.2026 OMe
			,	Target.id_vertrag	=	Source.id_vertrag



	WHEN NOT MATCHED BY TARGET THEN

		----- INSERT, weil noch nicht vorhanden -----


		INSERT (
			id_link_messeinheit
			,[id_mandant]
			,[id_zp]
			,[id_kunde]
			,[valid_from]
			,[valid_to]
			,[id_status]
			,[status]
			,[id_lieferant]
			,[wandlerfaktor]
			,[id_vertragsart]
			,[vertragsart]
			,[jahresverbrauch]
			,[created_at]
			,[changed_at]
			,[active]
			,id_vertrag
		)
		VALUES (
				Source.id_link_messeinheit
			,	Source.[id_mandant]
			,	Source.[id_zp]
			,	Source.[id_kunde]
			,	Source.[valid_from]
			,	Source.[valid_to]
			,	Source.[id_status]
			,	Source.[status]
			,	Source.[id_lieferant]

			,	Source.[wandlerfaktor]
			,	Source.[id_vertragsart]
			,	Source.[vertragsart]
			,	Source.[jahresverbrauch]

			,	Source.[created_at]
			,	Source.[changed_at]

			,	Source.[active]

			,	Source.id_vertrag
		)

	;
		
	--	---------------------------------------------------
	--	---------------------------------------------------
	END TRY
	--	---------------------------------------------------
	BEGIN CATCH
		-- Fehlermeldung zusammenbauen
		DECLARE @Message varchar(MAX) = CONCAT('Abbruch DWH: ', @SP_NAME, ' ### ',  ERROR_MESSAGE());

		-- Fehlermeldung ins Job Log Detail schreiben
		INSERT INTO [admin].[transform_log_detail] ([transform_job_id],[transform_routine],[transform_message])
		VALUES (@transform_job_id, @SP_NAME, @Message);

		-- Hier noch den Fehler eskalieren, damit abgebrochen wird
		THROW 51111, @Message, 1;

	END CATCH;

	--	---------------------------------------------------
	IF @verbose = 1 -- Exec Log Detail with SP Name
		INSERT INTO [admin].[transform_log_detail] ([transform_job_id],[transform_routine],[transform_message])
		VALUES (@transform_job_id, @SP_NAME, 'Ende')


END;

GO
