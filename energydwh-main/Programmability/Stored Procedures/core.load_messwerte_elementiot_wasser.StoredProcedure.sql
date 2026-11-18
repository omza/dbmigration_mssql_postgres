-- Object: core.load_messwerte_elementiot_wasser
-- Type  : SQL_STORED_PROCEDURE



/*
-- =============================================
-- Author:		Oliver Meyer
-- Create date: 22.10.2025
-- Description:	Füllt mit jeder Messung (getriggert aus dem Websocket-Repo) die Messwerte für Wasser messungen 


	Beispieldaten aus element:
 
				[
				{
				"meta": 
				null,
				"parser_id": "a30b97a8-8372-4650-80d7-e6c3f3449ef6",
				"device_id": "c338b2f3-75ad-40a0-a6d6-1441c370506e",
				"packet_id": "00ff041c-67f7-410b-8ba5-c77048e3266b",
				"location": 
				null,
				"inserted_at": 
				"2025-10-22T00:16:25.188787Z",
				"measured_at": 
				"2025-10-22T00:16:25.111875Z",
				"data": 
				{
				"value": 
				77525,
				"value_m3": 
				77.525
				},
				"id": 
				"8b8e8b37-900e-407f-9b24-86c0697d0b0c"
				}
				]

-- Change Log
-- ----------


-- Test
-- ----

  	declare
		@device_id nvarchar(36) = 'c338b2f3-75ad-40a0-a6d6-1441c370506e'
		,@parser_id nvarchar(36) = 'a30b97a8-8372-4650-80d7-e6c3f3449ef6'
		,@measured_at datetime = convert(datetime,'2025-10-22T13:34:51.822',126)
		,@data nvarchar(max) = '{"value":77525,"value_m3":77.525}' 

		exec core.[load_messwerte_elementiot_wasser] @device_id, @parser_id, @measured_at, @data

		select * from core.messwerte where id_messpunkt = 31637  id_obis in (30180,40180,60180)
		delete from core.messwerte where id_messpunkt = 31637

-- =============================================
*/
CREATE PROCEDURE [core].[load_messwerte_elementiot_wasser]
	-- Add the parameters for the stored procedure here
	@device_id nvarchar(36)
	,@parser_id nvarchar(36)
	,@measured_at datetime
	,@data nvarchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Get SP Name
	DECLARE 
		@SP_NAME varchar(100) = OBJECT_NAME(@@PROCID)
		,@Message varchar(MAX) = ''
		,@RETURNCODE int = 0


	BEGIN TRY
	--	---------------------------------------------------

	if @parser_id = 'a30b97a8-8372-4650-80d7-e6c3f3449ef6' -- nur Wasserzählerzaehler
	begin

		-- Insert statements for procedure here
		declare 
			@id_quellsystem int = 2
			,@id_messpunkt int = null
			,@messung_am datetime = null
			,@minutes_offset int = null
			,@tag date = null
			,@id_typtag int = null
			,@id_zeitumstellung int = null
			,@bstunde varchar(1) = null
			,@zaehlerstand_m3 decimal(15,3) = null
			,@id_obis int = null


		-- Prüfe ob Device Id als Messpunkt vorhanden ist
		select top 1
			@id_messpunkt = id_messpunkt,
			@id_obis = case		
							when id_energieart = 3 then 30180
							when id_energieart = 4 then 40180
							when id_energieart = 6 then 60180
							else null
						end
		from 
			core.messpunkte 
		where 
			id_quellsystem = @id_quellsystem 
			and messpunkt_ident = @device_id

		print @id_messpunkt
		print @id_obis

		IF @id_messpunkt > 0 and @id_obis > 0
		BEGIN

			-- ermittle CE(S)T zeitstempel für MESSUM_AM und isodate

			select 
				@minutes_offset = offset_minutes
				,@tag = [tag]
				,@id_typtag = id_typtag
				,@id_zeitumstellung = id_zeitumstellung
				,@bstunde = bstunde
			from 
				core.kalender 
			where 
				zeitstempel_utc = dateadd(hour, datepart(hour,@measured_at),CONVERT(datetime,CONVERT(date, @measured_at)))
			
			set @messung_am = dateadd(minute,@minutes_offset,@measured_at)

			print @messung_am
			print @tag

			IF @messung_am IS NOT NULL AND @tag IS NOT NULL
			begin
				

				set @zaehlerstand_m3 = TRY_CAST([stage].[json_value_from_key](@data,'value_m3') as DECIMAL(15,3))
				print @zaehlerstand_m3

				if @zaehlerstand_m3 > 0
					insert into [core].[messwerte] (
						[id_messpunkt]
						,[id_obis]
						,[messung_am]
						,[bstunde]
						,[tag]
						,[id_typtag]
						,[id_zeitumstellung]
						,[id_version]
						,[messwert]
						,[messeinheit]
						,[id_wertstatus]
						,[neu_flag]
					)
					select 
						@id_messpunkt
						,@id_obis
						,@messung_am
						,@bstunde
						,@tag
						,@id_typtag
						,@id_zeitumstellung
						,1
						,@zaehlerstand_m3
						,'m³'
						,0 
						,1
					where not exists (
						select 1 from [core].[messwerte] where id_messpunkt = @id_messpunkt and id_obis = @id_obis and messung_am = @messung_am and bstunde = @bstunde
					)


				SET @RETURNCODE = 1
			
					
			END

		END
	end
	else
		-- wenn parser nicht bekannt dann werfe fehler für den catchblock
		throw 51111, 'parser unbekannt', 1;

	--	---------------------------------------------------
	END TRY
	--	---------------------------------------------------
	BEGIN CATCH
		-- Fehlermeldung zusammenbauen
		SET @Message = CONCAT('Abbruch DWH: ', @SP_NAME, ' ### ',  ERROR_MESSAGE());
		PRINT @Message
		
		SET @RETURNCODE = 0

	END CATCH;
	--	---------------------------------------------------


	SELECT 
		@RETURNCODE as status,
		@Message as message


END

GO
