-- Object: admin.end_transform
-- Type  : SQL_STORED_PROCEDURE
/*
-- =============================================
-- Author:		Oliver Meyer
-- Create date: 14.11.2024
-- Description:	Schliesst das Loging ab

	Change Log:

	09.12.2024	OMe	Setzt gesperrte Transformationstrigger zur erneuten Ausführung zurück  
		Dies sollte der Logik nach gar nicht notwendig sein, weil

	15.07.2024	OME	fix errormessage zu lang
-- =============================================
*/
CREATE PROCEDURE [admin].[end_transform]
	@transform_job_id bigint,
	@transform_status tinyint,
	@transform_message nvarchar(max)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRY

		IF @transform_job_id > 0
		BEGIN


			declare 
				@transform_end_at datetime = GETDATE()

	
			-- Setzte Status auf Positionen
			UPDATE admin.transform_log
			SET 
				[transform_job_id] = @transform_job_id,
				[transform_end_at] = @transform_end_at,
				[transform_status] = @transform_status
			WHERE
				[transform_job_id] = @transform_job_id


			-- Setze Status und message auf Kopfsatz 
			UPDATE admin.transform_log
			SET 
				[transform_message] = ltrim(rtrim(left(@transform_message,500)))
			WHERE
				[transform_job_id] = @transform_job_id
				AND load_id = 0

			-- setze gesperrte Trigger zurück
			UPDATE admin.transform_log
			SET 
				[transform_job_id] = -1,
				[transform_status] = 0,
				transform_message = NULL
			WHERE
				[transform_job_id] = @transform_job_id
				and load_id > 0
				and transform_message = 'locked'
		END

	END TRY

	BEGIN CATCH
		SELECT
			@transform_job_id as transform_job_id,
			ERROR_MESSAGE() as transform_message

	END CATCH;

  
END

GO
