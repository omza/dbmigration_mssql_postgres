-- Object: dbo.addvalue
-- Type  : SQL_STORED_PROCEDURE

-- create a value for a property for an entity...

create   procedure [dbo].[addvalue] @property nvarchar(50), @value nvarchar(75), @entity_id bigint
as
begin

begin tran

declare @property_id bigint
select @property_id = id from property where name = @property

if @property_id is null
begin
	insert into property values(@property)
	set @property_id = scope_identity()
end

declare @old_value nvarchar(75)

select top 1 @old_value = [value]
from [value]
where @property_id = property_id and @entity_id = entity_id 
order by valid_since

if @value != @old_value or @old_value is null
begin
	declare @value_id bigint
	insert into [value] values(@property_id, @entity_id,@value, getdate())
	set @value_id = scope_identity()
end

--insert into assignment values(@entity, @value_id)

commit 
end

GO
