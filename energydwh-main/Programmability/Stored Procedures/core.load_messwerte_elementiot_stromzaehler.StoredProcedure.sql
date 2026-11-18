-- Object: core.load_messwerte_elementiot_stromzaehler
-- Type  : SQL_STORED_PROCEDURE


/*
-- =============================================
-- Author:		Oliver Meyer
-- Create date: 10.10.2025
-- Description:	Füllt mit jeder Messung (getriggert aus dem Websocket-Repo) die Messwerte für stromzähler messungen 


	Beispieldaten aus element:
		[{"body":{"meta":null,"parser_id":"d0198023-f115-4cf3-83aa-f3584afe5282","device_id":"1c30eaf0-ccf0-4850-af11-2470746f64f1","packet_id":"18c85f11-be37-44b2-b84e-10636f18a328","location":null,"inserted_at":"2025-10-10T12:19:15.209062Z","measured_at":"2025-10-10T12:19:15.121607Z",
		"data":{"command":"push","obis_16_7_0":119.18,"obis_1_8_0":360.598,"obis_2_8_0":2.188,"vendor_id":"1EBZ0103422745"},
		"id":"ec29c98a-ca97-46e2-92b0-fb0e526e2dcd"},"event":"reading_added"}]

-- Change Log
-- ----------


-- Test
-- ----

  	declare
		@device_id nvarchar(36) = '1c30eaf0-ccf0-4850-af11-2470746f64f1'
		,@parser_id nvarchar(36) = 'd0198023-f115-4cf3-83aa-f3584afe5282'
		,@measured_at datetime = convert(datetime,'2025-10-10T12:19:15.121',126)
		,@data nvarchar(max) = '{"command":"push","obis_16_7_0":119.18,"obis_1_8_0":360.598,"obis_2_8_0":2.188,"vendor_id":"1EBZ0103422745"}' 

		exec core.load_messwerte_elementiot_stromzaehler @device_id, @parser_id, @measured_at, @data

-- =============================================
*/
CREATE PROCEDURE core.load_messwerte_elementiot_stromzaehler
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

	if @parser_id = 'd0198023-f115-4cf3-83aa-f3584afe5282' -- nur Stromzaehler
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
				
				-- 1-1.1.8.0
				set @zaehlerstand_bezug = TRY_CAST([stage].[json_value_from_key](@data,'obis_1_8_0') as DECIMAL(15,3))

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
						,11180
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
						select 1 from [core].[messwerte] where id_messpunkt = @id_messpunkt and id_obis = 11180 and messung_am = @messung_am and bstunde = @bstunde
					)

				-- 1-1.2.8.0
				set @zaehlerstand_einspeisung = TRY_CAST([stage].[json_value_from_key](@data,'obis_2_8_0') as DECIMAL(15,3))

				if @zaehlerstand_einspeisung > 0
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
						,11280
						,@messung_am
						,@bstunde
						,@tag
						,@id_typtag
						,@id_zeitumstellung
						,1
						,@zaehlerstand_einspeisung
						,'kWh'
						,0 
						,1
					where not exists (
						select 1 from [core].[messwerte] where id_messpunkt = @id_messpunkt and id_obis = 11280 and messung_am = @messung_am and bstunde = @bstunde
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
