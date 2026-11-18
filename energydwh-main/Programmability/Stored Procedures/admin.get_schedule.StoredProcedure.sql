-- Object: admin.get_schedule
-- Type  : SQL_STORED_PROCEDURE
/* =============================================
-- Author:		Oliver Meyer
-- Create date: 18.07.2024
-- Description:	
	
	Ermittelt anhand der Systemzeit und der Pipeline die zu landenden Tabellen
	Legt für die zu ladenen Tabellen zum Start ein load_log an in den dann die lademeasures eingehen 

-- Change Log

	13.08.2024	OME Dynamic SQL 
	15.08.2024	OME	Deltaload Query in Cursor
	16.08.2024	OME	Initialload für Delta (Wenn dest Tabelle nicht vorhanden) dann einen Full load
	21.08.2024	OME	Aufnahme Testbetrieb mit eingestelltem Job
	26.08.2024	OME	Mhm... Wenn sich Jobs überholen hilft auch alles paralellisieren nichts ;-(
					Weitere Manuelle Tests und ggf. Änderung des Konzeptes

-- Config load

	INSERT INTO [admin].[load_config]
		([load_pipeline]
		,[load_type]
		,[src_location]
		-- ,[src_columns]
		,[src_filter]
		,[src_delta_conditions]
		,src_delta_key
		,[dest_table]
		,[load_start]
		,[load_interval_minutes],
		src_full_query)
	VALUES
		('Wilken_Generic'
		,'delta'
		,'CREATOR.ENKNDVERBRAUCHABGR'
		-- ,'GER_ID, GER_BEZEICHNUNG, GER_GERAETEGRUNDTYP, GER_STANDARD, GER_AUTO_NR, GER_AUTO_NR_PRAEFIX, GER_AUTO_NR_LAENGE, GER_ANGELEGT, GER_GEAENDERT'
		,'KNV_STATISTIKRELEVANT = 1'
		,'KNV_ANGELEGT >= TO_DATE(''{KNV_ANGELEGT}'',''YYYY-MM-DD HH24:MI:SS'')'
		,'KNV_ID'
		,'wilken_enkndverbrauchabgr'
		,CONVERT(DATETIME,'2024-08-12 01:00:00',120 ) -- yyyy-mm-dd hh:mi:ss (24-hour)
		,10080 -- 1440 täglich 10080 Wöchentlich (alle sieben Tage)
		,NULL) 


-- Test:

		exec admin.get_schedule 'Wilken_Generic'


-- ============================================= 
--*/
CREATE PROCEDURE [admin].[get_schedule] 
	-- Add the parameters for the stored procedure here
	@load_pipeline VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @SCHEDULE DATETIME = GETDATE()
	DECLARE @scheduled_at datetime = dateadd(minute, datediff(minute, '1900-01-01', dateadd(second, 150, @SCHEDULE))/5*5, 0)

	DECLARE @job_id INT = (
		SELECT ISNULL(MAX(job_id),0) + 1 from admin.load_log
	)


    -- Lade alle Configs die über den Schedule dran sind
	INSERT INTO [admin].[load_log]
	(
		job_id, load_config_id, scheduled_at, next_execution
	)
	SELECT
		@job_id,
		load_config_id,
		@scheduled_at,
		DATEADD(MINUTE,load_interval_minutes, @scheduled_at) as next_execution
	from
	(
		SELECT 
			*
		from
			admin.load_config
		where
			load_pipeline = @load_pipeline
			and load_config_id = 8
			/*AND (
				DATEDIFF(MINUTE,load_start,@scheduled_at) % load_interval_minutes = 0 -- Mehrfaches vom Interval ? dann ist die Tabelle dran 
				OR DATEDIFF(MINUTE,load_start,@scheduled_at) = 0 -- oder natürlich zum Startzeitpunkt
			)
			AND load_config_id not IN (SELECT DISTINCT load_config_id from admin.load_log where scheduled_at = @scheduled_at)*/
	) SCHEDULED

	-- Lade alle verzögerten Configs ebenfalls (next execution ermittlung aufpassen)
	-- Wird gemacht, wenn Konzept übernommen wird bzw. Energy DWH an leben kommt




	-- Markiere alle offenen Jobs der selben config als erledigt (bis auf den letzten)
	-- unerfüllte schedules 
	UPDATE admin.load_log
	SET 
		load_done = 1,
		load_message = 'discarded'
	where
		load_done = 0
		AND job_id <> @job_id
		AND load_config_id in (SELECT distinct load_config_id from admin.load_log where job_id = @job_id )


	-- ermittle src_query
	-- full load ist einfach
	UPDATE L
	SET
		src_query = CASE 
						WHEN ISNULL(src_location,'') = '' THEN src_full_query
						ELSE LTRIM(RTRIM('SELECT ' + ISNULL(src_columns,'*') + ' FROM ' + src_location + CASE WHEN ISNULL([src_filter],'') = '' THEN '' ELSE ' WHERE ' + [src_filter] END ))
					END
	FROM			
		admin.load_log L
	JOIN
		admin.load_config C ON L.load_config_id = C.load_config_id 	
	WHERE
		job_id = @job_id
		and C.load_type = 'full'


	-- ermittle initial loads für Deltas
	--
	UPDATE L
	SET
		src_query =  LTRIM(RTRIM('SELECT ' + src_delta_key + ' as key, ' +  
			CASE WHEN ISNULL(src_columns,'*') = '*' THEN src_location + '.*' ELSE src_columns END +
			+ ' FROM ' + src_location + CASE WHEN ISNULL([src_filter],'') = '' THEN '' ELSE ' WHERE ' + [src_filter] END )),
		load_initial = 1
	FROM			
		admin.load_log L
	JOIN
		admin.load_config C ON L.load_config_id = C.load_config_id 	
	WHERE
		job_id = @job_id
		and C.load_type = 'delta'
		and OBJECT_ID('raw.' + C.dest_table, 'U') IS NULL


	-- src_query für delta load ist schwieriger, weil mit cursor und dynamischer sql das maxdatum rausgeholt werden muß
	-- Erweiterung für max integer wenn Konzept übernommen wird
	
	DECLARE
		@load_log_id INT,
		@dest_table VARCHAR(MAX),
		@src_location VARCHAR(MAX),
		@src_columns VARCHAR(MAX),
		@src_filter VARCHAR(MAX),
		@src_delta_conditions VARCHAR(MAX),
		@src_delta_key VARCHAR(MAX),
		@maxdate VARCHAR(MAX), 
		@sql NVARCHAR(MAX),
		@query VARCHAR(MAX),
		@criteria VARCHAR(MAX)
	
	
	DECLARE delta_loads CURSOR FOR
		SELECT
			L.load_log_id,
			C.dest_table,
			C.src_location,
			C.src_columns,
			C.src_filter,
			C.src_delta_conditions,
			C.src_delta_key
		FROM
			admin.load_log L
		JOIN
			admin.load_config C ON L.load_config_id = C.load_config_id 	
		WHERE
			job_id = @job_id
			and C.load_type = 'delta'
			and OBJECT_ID('raw.' + C.dest_table, 'U') IS NOT NULL

	OPEN delta_loads

	FETCH NEXT FROM delta_loads INTO
		@load_log_id ,
		@dest_table ,
		@src_location,
		@src_columns ,
		@src_filter ,
		@src_delta_conditions,
		@src_delta_key 

	WHILE @@FETCH_STATUS = 0
	BEGIN

		-- Cursor für die src query mit criteria füllen
		select @query = LTRIM(RTRIM('SELECT ' + @src_delta_key + ' as key, ' + 
			CASE WHEN ISNULL(@src_columns,'*') = '*' THEN @src_location + '.*' ELSE @src_columns END +
			' FROM ' + @src_location + ' WHERE ' +
			CASE WHEN ISNULL(@src_filter,'') = '' THEN '' ELSE @src_filter + ' AND ' END +
			@src_delta_conditions
		))
		print @query

		-- Hier alle {} Parameter (nur Datum) aus den DeltaKriterien splitten und
		DECLARE delta_criteria CURSOR FOR
		select deltavar from admin.getdeltavar(@src_delta_conditions)

		OPEN delta_criteria
		FETCH NEXT FROM delta_criteria INTO @criteria

		WHILE @@FETCH_STATUS = 0
		BEGIN


			SET @sql = N'SELECT @maxdate = CONVERT(VARCHAR,MAX('+ @criteria + '),120) FROM raw.' + @dest_table  + ';'
			print @sql

			EXEC sp_executesql @sql, N'@maxdate VARCHAR(MAX) OUTPUT', @maxdate OUTPUT;

			SET @maxdate = CASE WHEN LEN(@maxdate) = 10 THEN @maxdate + ' 00:00:00' ELSE @maxdate END

	

			SET @query = REPLACE(@query, '{' + @criteria + '}',@maxdate)

			FETCH NEXT FROM delta_criteria INTO @criteria

		END

		CLOSE delta_criteria
		DEALLOCATE delta_criteria

		-- Zusammengestellte Query speichern
		Update admin.load_log SET src_query = @query where load_log_id = @load_log_id


		-- Get the next delta load
		FETCH NEXT FROM delta_loads INTO
			@load_log_id ,
			@dest_table ,
			@src_location,
			@src_columns ,
			@src_filter ,
			@src_delta_conditions,
			@src_delta_key 


	END
	CLOSE delta_loads;
	DEALLOCATE delta_loads;



	--tbd
	-- Output für den Talend job
	SELECT
		C.load_pipeline,
		load_log_id,
		CASE WHEN load_initial = 1 THEN 'full' ELSE load_type END as load_type,
		L.src_query,
		dest_table as dest_table
	FROM
		admin.load_log L
	JOIN
		admin.load_config C ON L.load_config_id = C.load_config_id 
	WHERE
		job_id = @job_id
		and load_done = 0
END

GO
