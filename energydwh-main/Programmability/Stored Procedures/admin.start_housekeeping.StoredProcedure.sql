-- Object: admin.start_housekeeping
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Führt ein housekeeping über die admin log_tabellen durch und entsperrt veraltete Ladelogeinträge
	Nur einmal am Tag!

	Es wird über die [core].[energydhw_transform_main] nach der Beladung aufgerufen


-- Change Log

	13.07.2026	OME initial
	


-- Test:

	exec admin.[start_housekeeping] -1 


-- ============================================= 
--*/


CREATE PROCEDURE	[admin].[start_housekeeping]
	@transform_job_id bigint
AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Get SP Name
	DECLARE @SP_NAME varchar(100);
	SELECT @SP_NAME = OBJECT_NAME(@@PROCID);


	-- Ist das housekeeping heute schon gelaufen ?
	declare @last_run as date
	select
		@last_run = cast(isnull(max([transform_timestamp]),'1900-01-01') as Date) 
	from
		[admin].[transform_log_detail]
	where
		[transform_routine] = @SP_NAME
	group by
		transform_routine

	if @@ROWCOUNT = 0 or @last_run < cast(getdate() as date)
	begin

		declare @max_tage_aufbewahrung int = 90

		BEGIN TRY
		--	---------------------------------------------------

			-- Start
			INSERT INTO [admin].[transform_log_detail] ([transform_job_id],[transform_routine],[transform_message])
			VALUES (@transform_job_id, @SP_NAME, 'Start')
	
			-- lösche load log
			delete from [admin].[load_log] where [load_start_at] < cast(dateadd(DAY,@max_tage_aufbewahrung*-1,getdate()) as date)

			-- lösche transform_log
			delete from [admin].[transform_log] where [transform_job_id] > 0 and [transform_start_at] < cast(dateadd(DAY,@max_tage_aufbewahrung*-1,getdate()) as date)

			-- lösche [admin].[transform_log_detail]
			delete from [admin].[transform_log_detail] where [transform_timestamp] < cast(dateadd(DAY,@max_tage_aufbewahrung*-1,getdate()) as date)

			-- setzte offene Lade logs zurück
			-- Annahme = eine Ladelog welches länger als einen Tag läuft ist fehlerhaft und sollte geschlossen werden
			update [admin].[load_log] 
			set
				load_status = 2,
				load_end_at = getdate(),
				load_message = isnull(load_message,'log durch housekeeping geschlossen')
			where
				cast(load_start_at as date) <= cast(dateadd(day,-1,getdate()) as date)
				and (load_end_at is null or load_status = 0)



			-- Ende
			INSERT INTO [admin].[transform_log_detail] ([transform_job_id],[transform_routine],[transform_message])
			VALUES (@transform_job_id, @SP_NAME, 'Ende')
		
	
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
	end

END;

GO
