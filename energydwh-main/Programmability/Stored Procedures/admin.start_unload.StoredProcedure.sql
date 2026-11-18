-- Object: admin.start_unload
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Create date: 22.05.2026
-- Description:	
	
	Legt für die zu entladenen Tabellen zum Start ein unload_log an, in den dann die entlademeasures eingehen 
	entladen werden zum Beispiel Datenqualitätsabfragen an Fachbereiche, die dann in der Tabelle mitgeloggt werden können.

-- Change Log

	22.05.2026	OME initial version
	


-- Test:

	exec admin.[start_unload] 'dqm_test', 'SELECT * FROM CREATOR.ENMES', 'email', 'omeyerzualtenschildesche@stadtwerke-norderstedt.de'


-- ============================================= 
--*/
CREATE PROCEDURE [admin].[start_unload]
	-- Add the parameters for the stored procedure here
	@unload_job VARCHAR(100),
	@src_query VARCHAR(max),
	@destination VARCHAR(100),
	@receipents VARCHAR(100) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @unload_id as bigint = -1

    -- Starte Load log

	INSERT INTO [admin].[unload_log]
    (
		[unload_job]
		,[unload_start_at]
		,[src_query]
		,[destination]
		,[recipient]
	)
	SELECT
		@unload_job,
		GETDATE(),
		@src_query,
		@destination,
		@receipents

	SET @unload_id = @@IDENTITY

	-- Output für den Talend job
	SELECT
		unload_id,
		src_query
	FROM
		admin.unload_log
	WHERE
		unload_id = @unload_id

END

GO
