-- Object: admin.start_transform
-- Type  : SQL_STORED_PROCEDURE
/*
-- =============================================
-- Author:		Oliver Meyer
-- Create date: 14.11.2024
-- Description:	Generiert eine neue Transform Job ID mit allen dazugehörigen Source Objekten
	-- Gibt die Job ID zurück an das Hauptprogramm

	Change Log: 
		04.02. Schreibe Transform ID nur rein, wenn etwas zu verarbeiten war

	09.12.2024	OMe	Ermittle Tabellen die gerade geladen werden und setze ein Merkmal, das Transformationen mit gesperrten Tabellen nicht durchgeführt werden
	04.04.2025	OMe	Setze abgebrochene Jobs auf Fehler (abgebrochen = nicht beendete Jobs für die eine späterer erfolgreicher Job existiert. Annahme: keine parallele Einplanung des selben Talend Jobs)
	16.07.2025	OMe	Verbose
	01.04.2026	OMe	Transformations ID für einzelne SP generieren

	Test: 
	exec [admin].[start_transform] 1

-- =============================================
*/
CREATE PROCEDURE [admin].[start_transform] 
	@verbose int = 0,
	@sp_transform nvarchar(4000) = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	DECLARE
		@transform_job_id bigint = -1,
		@transform_count int = 0,
		@transform_locked int = 0

	BEGIN TRY

		SET @transform_job_id = (select isnull(max(transform_job_id),0)+1 from admin.transform_log)
		IF @verbose > 0 SELECT @transform_job_id

		-- Standard Aufruf ohne Einzelsp
		IF @sp_transform = ''
		BEGIN

			-- Bestimme geänderte Source tabellen 
			UPDATE admin.transform_log
			SET 
				[transform_job_id] = @transform_job_id,
				[transform_start_at] = GETDATE()
			WHERE
				[transform_status] = 0
				AND [transform_job_id] = -1

			set @transform_count = @@ROWCOUNT

			-- Test
			IF @verbose > 0 SELECT * FROM admin.transform_log WHERE [transform_job_id] = @transform_job_id

			IF @transform_count > 0
			BEGIN

				-- unvollständige loads abbrechen wenn ein erfolgreicher nachfolge-load vorhanden
				WITH loadlogs AS (

					SELECT
						max(case when load_status = 1 then load_start_at else null end) over (partition by dest_table) as max_start,
						*
					FROM
						admin.load_log
					WHERE
						dest_table in (select distinct transform_source from admin.transform_log where transform_job_id = @transform_job_id)

				)
				UPDATE loadlogs 
				SET
					load_status = 2,
					load_end_at = getdate(),
					load_message = isnull(load_message,'abgebrochen weil erfolgreicher nachfolger')
				FROM 
					loadlogs
				WHERE
					load_start_at < isnull(max_start, load_start_at)
					and (load_end_at is null or load_status = 0)


				-- markiere trigger die gesperrt werden, weil die korrespondirende rawtabelle parallel durch einen anderen job gerade beladen wird
				UPDATE T
				SET 
					[transform_message] = 'locked'
				FROM
					[admin].[transform_log] T 
				JOIN
					admin.load_log L 
				ON 
					T.transform_source = L.dest_table 
					AND L.load_status = 0 -- wird gerade geladen
				WHERE
					[transform_job_id] = @transform_job_id

				set @transform_locked = @@ROWCOUNT

				-- Test
				IF @verbose > 0 SELECT * FROM admin.transform_log WHERE [transform_job_id] = @transform_job_id

				if @transform_count > @transform_locked
				BEGIN

					-- füge einen Kopfsatz ein
					INSERT INTO [admin].[transform_log] (
						[load_id]
					   ,[transform_job_id]
					   ,[transform_source]
					   ,[transform_triggered_at]
					   ,[transform_start_at]
					   ,[transform_status]
					)
					VALUES
					   (0, @transform_job_id,'Job Kopfsatz (transform main)', GETDATE(),GETDATE(),0)

					-- Output
					SELECT
						@transform_job_id as transform_job_id,
						'' as transform_message
				END
				ELSE
				BEGIN

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

					-- laufe nicht weiter
					SELECT
						-1 as transform_job_id,
						'alle transformationen gesperrt' as transform_message

				END

			END
			ELSE
				SELECT
					-1 as transform_job_id,
					'no need to run' as transform_message
		END
		-- Einzel SP Aufruf
		ELSE
		BEGIN

			-- Existiert die angegebene SP ?
			IF OBJECT_ID(@sp_transform, 'P') IS NOT NULL
			BEGIN

				-- füge einen Kopfsatz ein
				INSERT INTO [admin].[transform_log] (
					[load_id]
					,[transform_job_id]
					,[transform_source]
					,[transform_triggered_at]
					,[transform_start_at]
					,[transform_status]
				)
				VALUES
					(0, @transform_job_id, @sp_transform + ' (transform sp)', GETDATE(),GETDATE(),0)

				-- Output
				SELECT
					@transform_job_id as transform_job_id,
					'' as transform_message
			END
			ELSE
				SELECT
					-1 as transform_job_id,
					'sp does not exist' as transform_message
		END

	END TRY

	BEGIN CATCH
		SELECT
			-1 as transform_job_id,
			ERROR_MESSAGE() as transform_message

	END CATCH;

  
END

GO
