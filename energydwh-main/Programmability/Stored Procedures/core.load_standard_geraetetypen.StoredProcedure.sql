-- Object: core.load_standard_geraetetypen
-- Type  : SQL_STORED_PROCEDURE
/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt  die notwendigen Aktualisierungen durch für: core.standard_geraetetypen
	

-- Change Log

	04.02.2025	OME initial
	


-- Test:

	exec core.load_standard_geraetetypen -1, 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_standard_geraetetypen]
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
		
	/*
		wilken verarbeitung von Standard Zählertypen
	*/
	WITH TargetRows AS 
	(
		----- ZIEL -----



	SELECT 
		[id_mandant]
		,[id_energieart]
		,[standardgeraetetyp]
		,[wilken_sztp_nr]
		,[wilken_sztp_aktiv]
		,[created_at]
		,[changed_at]
		,checksum(
			[id_mandant]
			,[id_energieart]
			,[standardgeraetetyp]
			,[wilken_sztp_aktiv]
		) as [CHECKSUM]
	FROM 
		[core].[geraetetypen_standard]
	AS dim


		
		

	)
	MERGE INTO TargetRows	AS	Target
	USING
	(
		----- QUELLE -----
		SELECT 
			[id_mandant]
			,[id_energieart]
			,[SZTP_BEZEICHNUNG] as [standardgeraetetyp]
			,[SZTP_NR] [wilken_sztp_nr]
			,CAST([SZTP_AKTIV] as DECIMAL(1,0)) [wilken_sztp_aktiv]
			,[SZTP_ANGELEGT] as [created_at]
			,ISNULL([SZTP_GEAENDERT],[SZTP_ANGELEGT]) as [changed_at]
			,CHECKSUM (
				[id_mandant]
				,[id_energieart]
				,[SZTP_BEZEICHNUNG]
				,CAST([SZTP_AKTIV] as DECIMAL(1,0))
			) as [CHECKSUM]
		FROM 
			[raw].[wilken_ensztp] ztp
		JOIN
			core.mandant mnd on ztp.MND_ID = mnd.wilken_mnd_id
		JOIN
			core.energiearten eart on ISNULL(ztp.ENE_ID, 0) = eart.id_energieart 


		----- QUELLE -----
	)
	AS Source	ON		Source.[wilken_sztp_nr] = Target.[wilken_sztp_nr]  and Source.id_mandant = Target.id_mandant

	WHEN MATCHED AND Source.[CHECKSUM] != Target.[CHECKSUM] THEN
		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 

					Target.[id_energieart] =  Source.[id_energieart]
					,Target.[standardgeraetetyp] = Source.[standardgeraetetyp]
					,Target.[wilken_sztp_aktiv] = Source.[wilken_sztp_aktiv]
					,Target.[created_at] = Source.[created_at]
					,Target.changed_at	=	Source.changed_at
				

	WHEN NOT MATCHED BY TARGET THEN
		----- INSERT, weil noch nicht vorhanden -----
		INSERT (
           [id_mandant]
           ,[id_energieart]
           ,[standardgeraetetyp]
			,[wilken_sztp_nr]
			,[wilken_sztp_aktiv]
           ,[created_at]
           ,[changed_at]
		)
		VALUES (
           Source.[id_mandant]
           ,Source.[id_energieart]
           ,Source.[standardgeraetetyp]
           ,Source.[wilken_sztp_nr]
           ,Source.[wilken_sztp_aktiv]
           ,Source.[created_at]
           ,Source.[changed_at]
		);


	
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
