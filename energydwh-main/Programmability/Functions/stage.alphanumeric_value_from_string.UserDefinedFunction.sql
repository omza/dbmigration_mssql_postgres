-- Object: stage.alphanumeric_value_from_string
-- Type  : SQL_SCALAR_FUNCTION
CREATE FUNCTION stage.alphanumeric_value_from_string
(
    @input NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @output NVARCHAR(MAX) = '';
    DECLARE @i INT = 1;
    DECLARE @len INT = LEN(@input);
    DECLARE @char NCHAR(1);

    -- Loop through each character
    WHILE @i <= @len
    BEGIN
        SET @char = SUBSTRING(@input, @i, 1);

        -- Append only if NOT a digit 0-9
        IF @char NOT LIKE '[0-9]'
            SET @output += @char;

        SET @i += 1;
    END

    RETURN @output;
END

GO
