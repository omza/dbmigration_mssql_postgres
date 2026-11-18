-- Object: mart_energiemanagement.DIM_WERTSTATUS
-- Type  : VIEW




/*

DIM Wertstatus

*/


CREATE view [mart_energiemanagement].[DIM_WERTSTATUS] as


	select 
		[id_wertstatus]
		,[wertstatus]
	from 
		[core].[wertstatus]




GO
