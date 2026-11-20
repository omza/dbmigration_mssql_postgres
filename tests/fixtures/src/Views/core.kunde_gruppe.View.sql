-- Object: core.kunde_gruppe
-- Type  : VIEW
CREATE view [core].[kunde_gruppe] as
    select k.[id_kunde], 'K-' + k.[name] as anzeige, isnull(g.bezeichnung, 'ohne') as gruppe
    from core.kunde k
    left join core.gruppe g on g.id_gruppe = k.id_gruppe
    left join secret.geheim s on s.id = k.id_kunde
GO
