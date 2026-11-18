-- Object: core.load_dezem_messpunkte_und_werte
-- Type  : SQL_STORED_PROCEDURE




/* =============================================
-- Author:		Oliver Meyer
-- Create date: 23.04.2025
-- Description:	
	
	lädt die messpunkte und die messwerte aus den RZ2.1 CSV Exporten aus unserem deZem
		core.messpunkte
		core.messwerte
	

-- Change Log

	23.04.2025	OME initial
	29.04.2025	OME	bstunde für Zeitumstellung SW in Messwerttabelle hinzu



-- Test:

	exec core.[load_dezem_messpunkte_und_werte] -1, 'dezem_rz21_wtg', 0 -- verbose = 0 kein logging, verbose = 1 logging in admin.transform_log_detail


-- ============================================= 
--*/


CREATE PROCEDURE	[core].[load_dezem_messpunkte_und_werte]
	@transform_job_id bigint,
	@context nvarchar(100),
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

		DECLARE 
			@pos INT
			,@col_name NVARCHAR(100)
			,@id_geraetetyp int = (select top 1 id_geraetetyp from core.geraetetypen where id_quellsystem = 5)
			,@id_messpunkt int = Null	
			,@id_mandant int = 0 -- Messpunkt lässt sich keinem Mandanten zuordnen
			,@id_energieart int = 1 -- Strom
			,@id_geraeteart int = 1 -- Zähler
			,@id_quellsystem int = 5 -- deZem
			,@messpunkt_ident varchar(50) = ''
			,@messpunkt_name varchar(50) = ''
			,@messeinheit varchar(5) = ''
			,@sql nvarchar(max)

		IF OBJECT_ID('tempdb..#tmp_messwerte') IS NOT NULL DROP TABLE #tmp_messwerte

		CREATE TABLE #tmp_messwerte(
			[id_messpunkt] [int] NOT NULL,
			[id_obis] [int] NOT NULL,
			[messung_am] datetime not null,
			messwert [decimal](15, 3) NULL,
			[messeinheit] [varchar](5) NULL,
			id_version int null
		)

		DECLARE column_cursor CURSOR FOR
			SELECT 
				ORDINAL_POSITION,
				COLUMN_NAME
			FROM 
				INFORMATION_SCHEMA.COLUMNS
			WHERE 
				TABLE_SCHEMA = 'raw'
				and TABLE_NAME = @context
				and ORDINAL_POSITION > 1

		OPEN column_cursor

		FETCH NEXT FROM column_cursor
		INTO @pos, @col_name

		WHILE @@FETCH_STATUS = 0
		BEGIN

			/*
				im Cursor
				- Messpunkte bestimmen und im core aktualisieren
				- Messwerte in temporäre Tabelle per dynamischen sql erzeugen
		
				nach Cursor Verarbeitung
				- Messwerte aus temporärer Tabelle in core layer übertragen

			*/

			;with split_cols as (
	
				select
					n.*,
					ROW_NUMBER() OVER (ORDER BY n.Number desc) as Number_desc
				from
					[RealDWH].[dbo].[SplitStrings](@col_name, '|') n

			), messpunkte_raw as (

				select 
					case when Number = 1 then Item else Null end as messpunkt_name,
					case when Number_desc = 1 then Item else Null end as messpunkt_ident,
					case when Number = 2 and isnumeric(Item) = 0 then Item else Null end  as messeinheit
				from 
					split_cols

			)
			select
				@messpunkt_ident = ltrim(rtrim(left(max(messpunkt_ident),50)))
				,@messpunkt_name = ltrim(rtrim(left(max(messpunkt_name),50)))
				,@messeinheit = case 
									when max(messeinheit) = 'W' then 'Watt'
									else Null
								end
			from 
				messpunkte_raw

			-- Update
			UPDATE [core].[messpunkte] 
			SET 
				@id_messpunkt = id_messpunkt	
				,changed_at	=	GETDATE()
				,[id_energieart]	=	@id_energieart
				,id_mandant	=	@id_mandant
				,[id_geraeteart] =	@id_geraeteart
				,[id_geraetetyp] = @id_geraetetyp
				,[messpunkt_name]	=	@messpunkt_name
			WHERE
				id_quellsystem = @id_quellsystem
				and messpunkt_ident = @messpunkt_ident
			
			----- INSERT, weil noch nicht vorhanden -----
			if @id_messpunkt is null
			begin

				INSERT INTO [core].[messpunkte](
					[id_mandant]
					,[id_energieart]
					,[id_geraeteart]
					,[id_geraetetyp]
					,[id_quellsystem]
					,[messpunkt_ident]
					,[messpunkt_name]
				)
				VALUES (
					@id_mandant
					,@id_energieart
					,@id_geraeteart
					,@id_geraetetyp
					,@id_quellsystem
					,@messpunkt_ident
					,@messpunkt_name
				)
		
				set @id_messpunkt = @@IDENTITY

			end

			-- Messwerte in temporäre tabelle übertragen
			set @sql = N'INSERT INTO #tmp_messwerte (
							[id_messpunkt],
							[id_obis],
							[messung_am],
							messwert,
							[messeinheit],
							id_version
						) 
						SELECT
							' + cast(@id_messpunkt as nvarchar) + ', 
							11160,
							[Date(Europe/Berlin)],
							TRY_CAST(REPLACE([' + @col_name + '],'','',''.'') as DECIMAL(15,3)),
							''' + @messeinheit + ''' as Watt,
							1
						FROM 
							raw.' + @context
			--print (@col_name)
			--print (@sql)
			exec sp_executesql @sql

			set @id_messpunkt = Null

			-- Get the next column.
			FETCH NEXT FROM column_cursor
			INTO @pos, @col_name


		END
		CLOSE column_cursor;
		DEALLOCATE column_cursor;
	
		-- Merge Messwerte in tabelle
		--------------------------------------------------------------------------------------------------------------------------
		;WITH tmp_messwerte as (
		
			SELECT DISTINCT
				[id_messpunkt]
				,[id_obis]
				,[messung_am]
				,row_number() over (partition by id_messpunkt, messung_am order by id_messpunkt) as wert_reihenfolge
				,[tag]
				,[id_typtag]
				,[id_zeitumstellung]
				,w.[id_version]
				,[messwert]
				,[messeinheit]
				,0 [id_wertstatus] -- Wahrer Wert
				,1 [neu_flag]
			FROM 
				#tmp_messwerte w
			JOIN
				(select distinct tag, id_typtag, id_zeitumstellung from core.kalender) cal on CAST(w.[messung_am] as Date) = cal.tag
			WHERE
				messwert is not null		

		)
		MERGE INTO [core].[messwerte] AS Target
		USING
		(
			----- QUELLE -----
			SELECT DISTINCT
				[id_messpunkt]
				,[id_obis]
				,[messung_am]
				,case when wert_reihenfolge > 1 then 'b' else '' end bstunde
				,[tag]
				,[id_typtag]
				,[id_zeitumstellung]
				,[id_version]
				,[messwert]
				,[messeinheit]
				,[id_wertstatus] 
				,[neu_flag]
			FROM 
				tmp_messwerte
			----- QUELLE -----

		)	AS Source	
						ON		
								Source.id_messpunkt = Target.id_messpunkt 
							and Source.[id_obis] = Target.[id_obis]
							and Source.[messung_am] = Target.[messung_am]

		WHEN MATCHED AND (Source.[messwert] != Target.[messwert] OR Source.[messeinheit] != Target.[messeinheit]) THEN

			----- UPDATE, weil schon vorhanden -----
			UPDATE	SET 
						Target.changed_at	=	GETDATE()
					,	Target.messwert	=	Source.messwert
					,	Target.id_version = Target.id_version + 1
					,	Target.messeinheit = Source.messeinheit
					,   Target.neu_flag = 1


		WHEN NOT MATCHED BY TARGET THEN
			----- INSERT, weil noch nicht vorhanden -----
			INSERT (
				[id_messpunkt]
				,[id_obis]
				,[messung_am]
				,bstunde
				,[tag]
				,[id_typtag]
				,[id_zeitumstellung]
				,[id_version]
				,[messwert]
				,[messeinheit]
				,[id_wertstatus]
				,[neu_flag]
			)
			VALUES (
				Source.[id_messpunkt]
				,Source.[id_obis]
				,Source.[messung_am]
				,Source.bstunde
				,Source.[tag]
				,Source.[id_typtag]
				,Source.[id_zeitumstellung]
				,Source.[id_version]
				,Source.[messwert]
				,Source.[messeinheit]
				,Source.[id_wertstatus] 
				,Source.[neu_flag]
			);
	

	--	Bereinigen der raw tabelle bis zum letzten Zeitstempel
	--  -----------------------------------------------------------------------------------------------------------
	set @sql = N'DELETE FROM raw.' + @context +' WHERE [Date(Europe/Berlin)] NOT IN (SELECT MAX([Date(Europe/Berlin)]) [Date(Europe/Berlin)] FROM raw.' + @context +')'
	exec sp_executesql @sql


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
