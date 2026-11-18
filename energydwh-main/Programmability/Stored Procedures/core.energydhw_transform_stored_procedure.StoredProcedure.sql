-- Object: core.energydhw_transform_stored_procedure
-- Type  : SQL_STORED_PROCEDURE





/* =============================================
-- Author:		Oliver Meyer
-- Create date: 01.04.2026
-- Description:	
	
	Führt einzelne Transformations Stored Procedures im DWH und in den Martlayern durch
	
-- Change Log
	01.04.2026	OME initial


-- Test:
	exec core.[energydhw_transform_stored_procedure]  -1, N'[mart_dsai].[load_kunden_milieus]', 0


-- ============================================= 
--*/
CREATE PROCEDURE [core].[energydhw_transform_stored_procedure]
	@transform_job_id bigint
	,@sp_transform nvarchar(4000)
	,@verbose int = 0
AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.
	SET NOCOUNT ON;


	BEGIN TRY

		DECLARE
			@sql NVARCHAR(MAX),
			@query VARCHAR(MAX),
			@criteria VARCHAR(MAX)

		-- sp ausführen (Standard Interface)

		SET @sql = N'exec ' + @sp_transform  + ' ' + cast(@transform_job_id as nvarchar) +', ' + cast(@verbose as nvarchar) +';'
		print @sql

		EXEC sp_executesql @sql;
		

		-- Job id wurde bereits abgearbeitet
		SELECT
			@transform_job_id as transform_log_id,
			1 as transform_status,
			'Job wurde fehlerfrei ausgeführt' as transform_message	


	END TRY
	BEGIN CATCH

		SELECT
			@transform_job_id as transform_job_id,
			2 as transform_status,
			ERROR_MESSAGE() as transform_message

	END CATCH

END

GO
