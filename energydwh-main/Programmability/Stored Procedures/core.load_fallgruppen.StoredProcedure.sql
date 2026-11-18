-- Object: core.load_fallgruppen
-- Type  : SQL_STORED_PROCEDURE



/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: 
		core.fallgruppen
	

-- Change Log

	22.07.2025	OME initial
	


-- Test:

	exec core.[load_fallgruppen] -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_fallgruppen]
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
			id
			,id_zp
			,id_energierichtung
			,id_fallgruppe
			,fallgruppe
			,fallgruppe_durchschnittsverbrauch
			,ermittelt_am
			,fallgruppe_von
			,fallgruppe_bis
			,active
			,created_at
			,changed_at

			,CHECKSUM(
				id_zp
				,id_energierichtung
				,id_fallgruppe
				,fallgruppe
				,fallgruppe_durchschnittsverbrauch
				,ermittelt_am
				,fallgruppe_von
				,fallgruppe_bis
				,active
				,created_at
				,changed_at
			) AS CHECKSUM
		FROM 
			[core].[fallgruppen]

		AS	Dim


	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		select  
			id
			,id_zp
			,id_energierichtung
			,id_fallgruppe
			,fallgruppe
			,fallgruppe_durchschnittsverbrauch
			,ermittelt_am
			,fallgruppe_von
			,fallgruppe_bis
			,active
			,created_at
			,changed_at
			,CHECKSUM(
				id_zp
				,id_energierichtung
				,id_fallgruppe
				,fallgruppe
				,fallgruppe_durchschnittsverbrauch
				,ermittelt_am
				,fallgruppe_von
				,fallgruppe_bis
				,active
				,created_at
				,changed_at
			) AS CHECKSUM
		from 
			[stage].[wilken_fallgruppen] 

		----- QUELLE -----
	)
	AS Source	ON	 Source.id = Target.id

	WHEN MATCHED AND Source.CHECKSUM != Target.CHECKSUM THEN

		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 

				Target.id_zp	=	Source.id_zp
			,	Target.id_energierichtung	=	Source.id_energierichtung
			,	Target.id_fallgruppe	=	Source.id_fallgruppe
			,	Target.fallgruppe	=	Source.fallgruppe
			,	Target.fallgruppe_durchschnittsverbrauch	=	Source.fallgruppe_durchschnittsverbrauch
			,	Target.ermittelt_am	=	Source.ermittelt_am
			,	Target.fallgruppe_von	=	Source.fallgruppe_von
			,	Target.fallgruppe_bis	=	Source.fallgruppe_bis
			,	Target.active	=	Source.active
			,	Target.created_at	=	Source.created_at
			,	Target.changed_at	=	Source.changed_at



	WHEN NOT MATCHED BY TARGET THEN

		----- INSERT, weil noch nicht vorhanden -----


		INSERT (
			id
			,id_zp
			,id_energierichtung
			,id_fallgruppe
			,fallgruppe
			,fallgruppe_durchschnittsverbrauch
			,ermittelt_am
			,fallgruppe_von
			,fallgruppe_bis
			,active
			,created_at
			,changed_at
		)
		VALUES (

				Source.id
			,	Source.id_zp
			,	Source.id_energierichtung
			,	Source.id_fallgruppe
			,	Source.fallgruppe
			,	Source.fallgruppe_durchschnittsverbrauch
			,	Source.ermittelt_am
			,	Source.fallgruppe_von
			,	Source.fallgruppe_bis
			,	Source.active
			,	Source.created_at
			,	Source.changed_at
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
