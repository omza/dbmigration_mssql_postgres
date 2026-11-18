-- Object: core.load_messwerte_elementiot_waerme
-- Type  : SQL_STORED_PROCEDURE



/*
-- =============================================
-- Author:		Oliver Meyer
-- Create date: 16.10.2025
-- Description:	Füllt mit jeder Messung (getriggert aus dem Websocket-Repo) die Messwerte für wärme messungen 


	Beispieldaten aus element:
	[{"body":{"meta":null,"parser_id":"9e10001f-56e5-402a-b3ef-07824bb8efd3","device_id":"8b247c12-90a3-4ebb-8c06-94309cac8ac7",
		"packet_id":"79411989-c22e-4fd8-8385-8ee1a10596d7","location":null,"inserted_at":"2025-10-16T14:34:51.925662Z","measured_at":"2025-10-16T14:34:51.822743Z",
		"data":{"6-0:1.0.0":8430.0,"energy":8430.0,"energy_unit":"kWh","error":"","error_codes":0,"fabrication_block":71651926,"fabrication_block_unit":"MeterID","flow":0.003,"flow_unit":"m³/h","function_field":"current_value","payload_style":0,"power":100,"power_unit":"W","return_temperature":25.0,"return_temperature_unit":"°C","supply_temperature":58.7,"supply_temperature_unit":"°C","volume":706.62,"volume_unit":"m³"}
		,"id":"afdcff32-f173-48bd-ab23-6b8b2324b072"},"event":"reading_added"}]

-- Change Log
-- ----------


-- Test
-- ----

  	declare
		@device_id nvarchar(36) = '8b247c12-90a3-4ebb-8c06-94309cac8ac7'
		,@parser_id nvarchar(36) = '9e10001f-56e5-402a-b3ef-07824bb8efd3'
		,@measured_at datetime = convert(datetime,'2025-10-16T16:34:51.822',126)
		,@data nvarchar(max) = '{"6-0:1.0.0":8430.0,"energy":8430.0,"energy_unit":"kWh","error":"","error_codes":0,"fabrication_block":71651926,"fabrication_block_unit":"MeterID","flow":0.003,"flow_unit":"m³/h","function_field":"current_value","payload_style":0,"power":100,"power_unit":"W","return_temperature":25.0,"return_temperature_unit":"°C","supply_temperature":58.7,"supply_temperature_unit":"°C","volume":706.62,"volume_unit":"m³"}' 

		exec core.[load_messwerte_elementiot_waerme] @device_id, @parser_id, @measured_at, @data

-- =============================================
*/
CREATE PROCEDURE [core].[load_messwerte_elementiot_waerme]
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

	if @parser_id in ('9e10001f-56e5-402a-b3ef-07824bb8efd3', '7718461f-13f0-4dbe-9085-fc1d36770686') -- nur Wärmezaehler
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
			,@zaehlerstand_bezug decimal(15,3) = null
			,@zaehlerstand_einspeisung decimal(15,3) = null


		-- Prüfe ob Device Id als Messpunkt vorhanden ist
		set @id_messpunkt = (select top 1 id_messpunkt from core.messpunkte where id_quellsystem = @id_quellsystem and messpunkt_ident = @device_id)

		IF @id_messpunkt > 0
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

			IF @messung_am IS NOT NULL AND @tag IS NOT NULL
			begin
				
				-- 50180
				set @zaehlerstand_bezug = TRY_CAST([stage].[json_value_from_key](@data,'energy') as DECIMAL(15,3))

				if @zaehlerstand_bezug > 0
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
						,50180
						,@messung_am
						,@bstunde
						,@tag
						,@id_typtag
						,@id_zeitumstellung
						,1
						,@zaehlerstand_bezug
						,'kWh'
						,0 
						,1
					where not exists (
						select 1 from [core].[messwerte] where id_messpunkt = @id_messpunkt and id_obis = 50180 and messung_am = @messung_am and bstunde = @bstunde
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
