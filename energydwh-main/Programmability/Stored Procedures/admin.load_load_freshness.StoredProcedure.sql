-- Object: admin.load_load_freshness
-- Type  : SQL_STORED_PROCEDURE



/* =============================================
-- Author:		Oliver Meyer
-- Description:	
	
	Pflegt die admin.load_freshness tabelle aus und meldet alle nicht frischen tabellen als dataset zurück
	

-- Change Log

	05.01.2026	OME initial
	23.01.2026	OMe Fix gelöschte Tabelle nicht kontrollieren	(Delete wenn kein match bei source)
	20.03.2026	OME Fix Tabellenbezeichnung beim Update in []

-- Test:

	exec [admin].[load_load_freshness]


-- ============================================= 
--*/


CREATE PROCEDURE	[admin].[load_load_freshness]
	
AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Get SP Name
	DECLARE @SP_NAME varchar(100);
	SELECT @SP_NAME = OBJECT_NAME(@@PROCID);


	BEGIN TRY
	--	---------------------------------------------------

	;WITH rawtables as (

		select
			schema_name(t.schema_id) as [schema]
			,cast(t.name as [nvarchar](128)) as dest_table
		from        
			sys.columns c
		join        
			sys.tables  t   on c.object_id = t.object_id
		where       
			c.name = 'load_at'
			and schema_name(t.schema_id) = 'raw'


	), loads as (

		select 
			[dest_table]
			,[load_id] as last_load_id
			,[load_start_at] as last_load_at
			,[load_status] as last_load_status

			,row_number() over (partition by [dest_table] order by [load_start_at] desc) as rang
			,DATEDIFF(day, LEAD(load_start_at,1,0)  over (partition by [dest_table] order by [load_start_at] desc), [load_start_at]) AS days_to_previous
		from
			[admin].[load_log]

	)
	MERGE INTO [admin].[load_freshness]	AS	Target
	USING
	(
		----- QUELLE -----
		select
			r.[schema]
			,r.dest_table
			,null max_load_at
			,last_load_id
			,last_load_at
			,last_load_status
			,case when isnull(days_to_previous,0) = 0 then 1 else days_to_previous end as max_days_age
			,0 freshness_ignore


		from
			rawtables r

		left join
			loads l on r.dest_table = l.dest_table and l.rang = 1

		----- QUELLE -----
	)
	AS Source	ON	 Source.dest_table = Target.dest_table

	WHEN MATCHED THEN

		----- UPDATE, weil schon vorhanden -----
		UPDATE	SET 

				Target.[last_load_id]	=	Source.[last_load_id]
			,	Target.[last_load_at]	=	Source.[last_load_at]
			,	Target.[last_load_status]	=	Source.[last_load_status]
			,	Target.[changed_at] = getdate()


	WHEN NOT MATCHED BY TARGET THEN

		----- INSERT, weil noch nicht vorhanden -----


		INSERT (
			[schema]
		  ,[dest_table]
		  ,[max_load_at]
		  ,[last_load_id]
		  ,[last_load_at]
		  ,[last_load_status]
		  ,[max_days_age]
		  ,[freshness_ignore]
		)
		VALUES (

				Source.[schema]
			,	Source.[dest_table]
			,	Source.[max_load_at]
			,	Source.[last_load_id]
			,	Source.[last_load_at]
			,	Source.[last_load_status]
			,	Source.[max_days_age]
			,	Source.[freshness_ignore]

		)

	WHEN NOT MATCHED BY SOURCE THEN
		DELETE
	;
		

	/*
		jetzt update für alle tabellen das max load at datum aus der jeweiligen Zieltabelle
	*/

	DECLARE
		@sql NVARCHAR(MAX),
		@dest_table nvarchar(128),
		@dest_schema nvarchar(128)

	DECLARE max_load_at CURSOR FOR
	select [schema], [dest_table] from admin.load_freshness

	OPEN max_load_at
	FETCH NEXT FROM max_load_at INTO @dest_schema, @dest_table

	WHILE @@FETCH_STATUS = 0
	BEGIN


		SET @sql = N'UPDATE admin.load_freshness SET max_load_at = (SELECT isnull(max(load_at),convert(datetime,''01.01.1900'',104)) FROM [' + @dest_schema + '].[' + @dest_table  + '] with (nolock)) 
						WHERE dest_table = ''' + @dest_table + ''''
		
		EXEC sp_executesql @sql

		FETCH NEXT FROM max_load_at INTO @dest_schema, @dest_table

	END

	CLOSE max_load_at
	DEALLOCATE max_load_at

	/*
		Ausgabe der nicht "freshen" tabellen

	*/

	select
      [dest_table]
      ,[max_load_at]
      ,[last_load_id]
      ,[last_load_at]
      ,[last_load_status]
      ,[max_days_age]	
	from
		[admin].[load_freshness]
	where
		freshness_ignore = 0
		and ( [last_load_status] <> 1 -- entweder alle nicht OK
			or 
				dateadd(DAY, [max_days_age] , case when [last_load_at] > [max_load_at] then [last_load_at] else [max_load_at] end) < GETDATE())
				-- oder alle deren max load at + max alter in tagen ist geringer als das ausführungsdatum

	
	--	---------------------------------------------------
	--	---------------------------------------------------
	END TRY
	--	---------------------------------------------------
	BEGIN CATCH
		-- Fehlermeldung zusammenbauen
		DECLARE @Message varchar(MAX) = CONCAT('Abbruch DWH: ', @SP_NAME, ' ### ',  ERROR_MESSAGE());


		-- Hier noch den Fehler eskalieren, damit abgebrochen wird
		THROW 51111, @Message, 1;

	END CATCH;



END;

GO
