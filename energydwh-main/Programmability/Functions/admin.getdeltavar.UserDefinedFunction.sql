-- Object: admin.getdeltavar
-- Type  : SQL_TABLE_VALUED_FUNCTION
CREATE FUNCTION admin.getdeltavar ( @stringToSplit VARCHAR(MAX) )
RETURNS
 @returnList TABLE (deltavar [nvarchar] (500))
AS
BEGIN

 DECLARE @name NVARCHAR(255)
 DECLARE @pos INT, @posa INT

 WHILE CHARINDEX('}', @stringToSplit) > 0
 BEGIN
	--Ende Kürzen
  SELECT @pos  = CHARINDEX('}', @stringToSplit) 
  SELECT @name = SUBSTRING(@stringToSplit, 1, @pos-1)
  
  -- Anfang kürzen
  SELECT @posa  = CHARINDEX('{', @name) 
  SELECT @name = SUBSTRING(@name, @posa+1, len(@name)-1)
  
  INSERT INTO @returnList 
  SELECT @name

  SELECT @stringToSplit = SUBSTRING(@stringToSplit, @pos+1, LEN(@stringToSplit)-@pos)
 END
 RETURN
END
GO
