-- Object: stage.json_value_from_key
-- Type  : SQL_SCALAR_FUNCTION

-- =============================================
-- Author:		Oliver Meyer (OMe)
-- Create date: 29.04.2025
-- Description:	parsed aus einem Json Content einen Value zum angegebenen key

/*
	Test
	====

	SELECT TOP (1) 
		device_id
		,[measured_at]
		,data
		,[stage].[json_value_from_key] (data,'air_temperature') as Temperatur
		,[stage].[json_value_from_key] (data,'relative_humidity') as Luftfeuchte
		,[stage].[json_value_from_key] (data,'wind_speed') as Windgeschwindigkeit
	FROM 
		[stage].[ELEMENTIOT_READINGS_WETTERSTATIONEN]

*/
-- =============================================
CREATE FUNCTION [stage].[json_value_from_key] 
(
	-- Add the parameters for the function here
	@json nvarchar(max),
	@key nvarchar(50)
)
RETURNS nvarchar(max)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @result nvarchar(max) = null


	-- lösche Listen aus dem json, da diese hier als scalare funktion sich nicht parsen lassen
	-- tbd


	-- Add the T-SQL statements to compute the return value here
	DECLARE @keyvalues table (Number int, Item nvarchar(max))

	INSERT INTO @keyvalues(Number, Item) 
	SELECT Number, Item 
	FROM stage.SplitStrings(@json, ',') 
	WHERE Item like '%' + @key + '%'

	if @@ROWCOUNT > 0

		-- Ersetzte die üblichen Json Zeichen wie textqualifier etc.  
		SELECT TOP 1
			@result = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(right(Item,Len(Item)-CHARINDEX(':',Item)),' ',''),'''',''),'}',''),'{',''), '"','')
		FROM
			@keyvalues


	-- Return the result of the function
	RETURN @result

END

GO
