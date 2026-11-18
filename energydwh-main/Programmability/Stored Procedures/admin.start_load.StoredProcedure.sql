-- Object: admin.start_load
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Create date: 13.09.2024
-- Description:	
	
	Legt für die zu ladenen Tabellen zum Start ein load_log an, in den dann die lademeasures eingehen 

	Verbesserungsvorschlag: Datentyp des Criterien Feldes abfragen und die Where Clause entsprechend anpassen

-- Change Log

	13.08.2024	OME Dynamic SQL 
	15.08.2024	OME	Deltaload Query in Cursor
	16.08.2024	OME	Initialload für Delta (Wenn dest Tabelle nicht vorhanden) dann einen Full load
	21.08.2024	OME	Aufnahme Testbetrieb mit eingestelltem Job
	26.08.2024	OME	Mhm... Wenn sich Jobs überholen hilft auch alles paralellisieren nichts ;-(
					Weitere Manuelle Tests und ggf. Änderung des Konzeptes
	13.09.2024	OME	refactoring
	09.01.2024	OME	Delta Load WHERE Clause fixen
	27.03.2025	OMe	Delta Load Where Clause fix wenn die dest table keine Datensätze enthält

-- Test:

	exec admin.[start_load] 'full', 'SELECT * FROM CREATOR.ENMES', 'wilken_enmes'


-- ============================================= 
--*/
CREATE PROCEDURE [admin].[start_load]
	-- Add the parameters for the stored procedure here
	@load_type VARCHAR(10),
	@src_query NVARCHAR(max),
	@dest_table VARCHAR(50),
	@src_delta_condition VARCHAR(MAX) = '',
	@dest_schema VARCHAR(50) = 'raw'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @load_id as bigint = -1

    -- Starte Load log

	INSERT INTO [admin].[load_log]
	(
		load_type, load_start_at, dest_table)
	SELECT
		@load_type,
		GETDATE(),
		@dest_table
	SET @load_id = @@IDENTITY

	-- Lade alle verzögerten Configs ebenfalls (next execution ermittlung aufpassen)
	-- Wird gemacht, wenn Konzept übernommen wird bzw. Energy DWH an leben kommt


	-- ermittle src_query
	-- full load ist einfach
	IF @load_type = 'full'


		UPDATE [admin].[load_log]
		SET
			src_query = @src_query
		WHERE
			load_id = @load_id

	ELSE 
	-- delta load
	--
	BEGIN

		-- ermittle initial loads für Deltas
		IF OBJECT_ID(@dest_schema +'.' + @dest_table, 'U') IS NULL

			UPDATE L
			SET
				src_query = @src_query,
				load_type = 'delta_init'
			FROM			
				admin.load_log L
			WHERE
				load_id = @load_id

		ELSE
		BEGIN

			-- src_query für delta load ist schwieriger, weil mit cursor und dynamischer sql das maxdatum rausgeholt werden muß
			-- Erweiterung für max integer wenn Konzept übernommen wird
	
			DECLARE
				@maxdate VARCHAR(MAX), 
				@sql NVARCHAR(MAX),
				@query VARCHAR(MAX),
				@criteria VARCHAR(MAX)
	

			-- Cursor für die src query mit criteria füllen
			-- wenn src_query eine where Clause enthält dann füge die deltakriterien MIT AND an sonst mit WHERE
			IF CHARINDEX('WHERE',@src_query) > 0
				select @query = @src_query + ' AND ' +	@src_delta_condition
			ELSE
				select @query = @src_query + ' WHERE ' +	@src_delta_condition
			--print @query

			-- Hier alle {} Parameter (nur Datum) aus den DeltaKriterien splitten und
			DECLARE delta_criteria CURSOR FOR
			select deltavar from admin.getdeltavar(@src_delta_condition)

			OPEN delta_criteria
			FETCH NEXT FROM delta_criteria INTO @criteria

			WHILE @@FETCH_STATUS = 0
			BEGIN


				SET @sql = N'SELECT @maxdate = ISNULL(CONVERT(VARCHAR,MAX('+ @criteria + '),120),''1999-01-01'') FROM ' + @dest_schema + '.' + @dest_table  + ';'
				print @sql

				EXEC sp_executesql @sql, N'@maxdate VARCHAR(MAX) OUTPUT', @maxdate OUTPUT;

				SET @maxdate = CASE WHEN LEN(@maxdate) = 10 THEN @maxdate + ' 00:00:00' ELSE @maxdate END

				SET @query = REPLACE(@query, '{' + @criteria + '}',@maxdate)

				FETCH NEXT FROM delta_criteria INTO @criteria

			END

			CLOSE delta_criteria
			DEALLOCATE delta_criteria

			-- Zusammengestellte Query speichern
			Update admin.load_log SET src_query = @query where load_id = @load_id

		END


	END

	--tbd
	-- Output für den Talend job
	SELECT
		@load_id,
		src_query,
		load_type
	FROM
		admin.load_log
	WHERE
		load_id = @load_id
END

GO
