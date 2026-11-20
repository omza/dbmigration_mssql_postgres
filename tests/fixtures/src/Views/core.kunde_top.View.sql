CREATE view [core].[kunde_top] as
    select top 10 * from [core].[kunde_gruppe] order by anzeige
GO
