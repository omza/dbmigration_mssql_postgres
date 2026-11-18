-- Object: admin.load_data_quality_log
-- Type  : SQL_STORED_PROCEDURE


/* =============================================
-- Author:		Oliver Meyer
-- Create date: 22.05.2026
-- Description:	
	
	Merkt sich für jede DWM Abfrage die Anzahl der Fehler je Fehlerbild

-- Change Log

	22.05.2026	OME initial version
	28.05.2026	OME Object Parameter hinzugefügt, damit die Ergebnisse auch nach DQM Objekt gefiltert werden können
	


-- Test:

	exec [admin].[load_data_quality_log] 'dqm_test', 'caigos', 'Technische Dokumentation','Gas Hausanschluss', '[mart_technische_doku].[dqm_caigos_gas_hausanschluss]'


-- ============================================= 
--*/
CREATE PROCEDURE [admin].[load_data_quality_log]
	-- Add the parameters for the stored procedure here
	@dqm_job varchar(100),
	@system varchar(100),
	@domain [varchar](100),
	@object varchar(100),
	@src_query varchar(max)


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	
	DECLARE
		@sql NVARCHAR(MAX)

	BEGIN TRY
		-- prüfe ob feld fehlerbild in der @src_query vorhanden ist, wenn ja, dann extrahiere die fehlerbilder und zähle die anzahl der fehler je fehlerbild
		-- und speichere die ergebnisse in der tabelle data_quality_log
		SET @sql = 
		N'MERGE [admin].[data_quality_log] AS target
		USING (select 
				''' + @dqm_job + ''' as dqm_job, 
				''' + @system + ''' as system, 
				''' + @domain + ''' as domain, 
				''' + @object + ''' as object, 
				fehlerbild as failure, 
				count(*) as count_rows, 
				cast(getdate() as date) as datum
			from 
				' + @src_query + '
			group by fehlerbild) AS src
		ON 
			target.system = src.system
			and target.domain = src.domain
			and target.object = src.object
			and target.failure = src.failure
			and target.datum = src.datum
		
		WHEN MATCHED THEN
			UPDATE SET
				target.dqm_job = src.dqm_job,
				target.count_rows = src.count_rows
		
		WHEN NOT MATCHED THEN
			INSERT ([dqm_job]
				  ,[system]
				  ,[domain]
				  ,[object]
				  ,[failure]
				  ,[count_rows]
				  ,[datum])
			VALUES (src.[dqm_job]
				  ,src.[system]
				  ,src.[domain]
				  ,src.[object]
				  ,src.[failure]
				  ,src.[count_rows]
				  ,src.[datum]);'

		--PRINT @sql
		EXEC sp_executesql @sql

		select
			'Datenqualitätsergebnisse gespeichert' as message

	END TRY
	BEGIN CATCH

		select
			'Fehlerbild Spalte nicht gefunden, keine Datenqualitätsergebnisse gespeichert.' as message;

		-- Hier noch den Fehler eskalieren, damit abgebrochen wird
		THROW 51111, 'Fehlerbild Spalte nicht gefunden, keine Datenqualitätsergebnisse gespeichert.', 1;

	END CATCH
END

GO
