CREATE TABLE [core].[link_netz_knoten_verbraucher]
(
    [id_link_netz_knoten_verbraucher] [sys].[int] IDENTITY(1,1) NOT NULL,
    [id_knoten] [sys].[int] NOT NULL,
    [faktor] [sys].[int] CONSTRAINT [DF__link_netz__fakto__0408D441] DEFAULT ((1)) NOT NULL,
    [id_zp] [sys].[int] NULL,
    [id_geraet] varchar(32) COLLATE Latin1_General_CI_AS NULL,
    [id_messpunkt] [sys].[int] NULL,
    [valid_from] [sys].[date] CONSTRAINT [DF__link_netz__valid__7F441F24] DEFAULT (CONVERT([datetime],'01.01.1900',(104))) NOT NULL,
    [valid_to] [sys].[date] CONSTRAINT [DF__link_netz__valid__0038435D] DEFAULT (CONVERT([datetime],'31.12.9999',(104))) NULL,
    [active] [sys].[int] CONSTRAINT [DF__link_netz__activ__0314B008] DEFAULT ((1)) NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__link_netz__creat__012C6796] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__link_netz__chang__02208BCF] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_link_netz_knoten_verbraucher] PRIMARY KEY CLUSTERED ([id_link_netz_knoten_verbraucher] ASC)
);

ALTER TABLE [core].[link_netz_knoten_verbraucher]
ADD CONSTRAINT [fk_link_netz_knoten_geraet]
FOREIGN KEY ([id_geraet])
REFERENCES [core].[geraete] ([id_geraet]);

ALTER TABLE [core].[link_netz_knoten_verbraucher]
ADD CONSTRAINT [fk_link_netz_knoten_knoten]
FOREIGN KEY ([id_knoten])
REFERENCES [core].[netz_knoten] ([id_knoten]);

ALTER TABLE [core].[link_netz_knoten_verbraucher]
ADD CONSTRAINT [fk_link_netz_knoten_melo]
FOREIGN KEY ([id_zp])
REFERENCES [core].[zaehlpunkte] ([id_zp]);

ALTER TABLE [core].[link_netz_knoten_verbraucher]
ADD CONSTRAINT [fk_link_netz_knoten_messpunkt]
FOREIGN KEY ([id_messpunkt])
REFERENCES [core].[messpunkte] ([id_messpunkt]);