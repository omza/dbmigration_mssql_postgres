CREATE TABLE [core].[link_zaehlpunkt_geraet]
(
    [id_link_zp_geraet] [sys].[int] NOT NULL,
    [id_mandant] [sys].[int] NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [id_zp] [sys].[int] NOT NULL,
    [id_geraet] varchar(32) COLLATE Latin1_General_CI_AS NOT NULL,
    [einbaudatum] [sys].[date] NOT NULL,
    [ausbaudatum] [sys].[date] NOT NULL,
    [id_status] [sys].[int] NOT NULL,
    [status] varchar(10) COLLATE Latin1_General_CI_AS NOT NULL,
    [created_at] [sys].[date] CONSTRAINT [DF__link_zaeh__creat__322EC64D] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[date] CONSTRAINT [DF__link_zaeh__chang__3322EA86] DEFAULT (getdate()) NOT NULL,
    [active] [sys].[int] CONSTRAINT [DF__link_zaeh__activ__34170EBF] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [pk_link_zaehlpunkt_geraet] PRIMARY KEY CLUSTERED ([id_link_zp_geraet] ASC)
);

ALTER TABLE [core].[link_zaehlpunkt_geraet]
ADD CONSTRAINT [fk_link_zaehlpunkt_geraet_geraet]
FOREIGN KEY ([id_geraet])
REFERENCES [core].[geraete] ([id_geraet]);

ALTER TABLE [core].[link_zaehlpunkt_geraet]
ADD CONSTRAINT [fk_link_zaehlpunkt_geraet_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);

ALTER TABLE [core].[link_zaehlpunkt_geraet]
ADD CONSTRAINT [fk_link_zaehlpunkt_geraet_zp]
FOREIGN KEY ([id_zp])
REFERENCES [core].[zaehlpunkte] ([id_zp]);

CREATE NONCLUSTERED INDEX [ix_link_zaehlpunkt_geraet_mandant_energieart_zp]
ON [core].[link_zaehlpunkt_geraet] ([id_mandant] ASC, [id_energieart] ASC, [id_zp] ASC)
INCLUDE ([id_link_zp_geraet], [id_geraet], [einbaudatum], [ausbaudatum], [id_status]);