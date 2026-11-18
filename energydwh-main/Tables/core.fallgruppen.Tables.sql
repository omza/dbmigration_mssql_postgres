CREATE TABLE [core].[fallgruppen]
(
    [id] [sys].[int] NOT NULL,
    [id_zp] [sys].[int] NOT NULL,
    [id_energierichtung] [sys].[int] NOT NULL,
    [id_fallgruppe] [sys].[int] NOT NULL,
    [fallgruppe] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [fallgruppe_durchschnittsverbrauch] decimal(13,2) NULL,
    [ermittelt_am] [sys].[date] NULL,
    [fallgruppe_von] [sys].[date] NULL,
    [fallgruppe_bis] [sys].[date] NULL,
    [active] [sys].[int] NOT NULL,
    [created_at] [sys].[datetime] NOT NULL,
    [changed_at] [sys].[datetime] NOT NULL,
    CONSTRAINT [pk_fallgruppen] PRIMARY KEY CLUSTERED ([id] ASC)
);

ALTER TABLE [core].[fallgruppen]
ADD CONSTRAINT [fk_fallgruppe_energierichtung]
FOREIGN KEY ([id_energierichtung])
REFERENCES [core].[energierichtungen] ([id_energierichtung]);

ALTER TABLE [core].[fallgruppen]
ADD CONSTRAINT [fk_fallgruppe_zaehlpunkt]
FOREIGN KEY ([id_zp])
REFERENCES [core].[zaehlpunkte] ([id_zp]);