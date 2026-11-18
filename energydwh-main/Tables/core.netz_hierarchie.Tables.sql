CREATE TABLE [core].[netz_hierarchie]
(
    [id_knoten] [sys].[int] NOT NULL,
    [id_knoten_parent] [sys].[int] NOT NULL,
    [valid_from] [sys].[date] CONSTRAINT [DF__netz_hier__valid__71EA2406] DEFAULT (CONVERT([datetime],'01.01.1900',(104))) NOT NULL,
    [valid_to] [sys].[date] CONSTRAINT [DF__netz_hier__valid__72DE483F] DEFAULT (CONVERT([datetime],'31.12.9999',(104))) NULL,
    [active] [sys].[int] CONSTRAINT [DF__netz_hier__activ__75BAB4EA] DEFAULT ((1)) NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__netz_hier__creat__73D26C78] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__netz_hier__chang__74C690B1] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_netz_hierarchie] PRIMARY KEY CLUSTERED ([id_knoten] ASC, [id_knoten_parent] ASC, [valid_from] ASC)
);

ALTER TABLE [core].[netz_hierarchie]
ADD CONSTRAINT [fk_netz_hierarchie_knoten]
FOREIGN KEY ([id_knoten])
REFERENCES [core].[netz_knoten] ([id_knoten]);

ALTER TABLE [core].[netz_hierarchie]
ADD CONSTRAINT [fk_netz_hierarchie_knoten_parent]
FOREIGN KEY ([id_knoten_parent])
REFERENCES [core].[netz_knoten] ([id_knoten]);