CREATE TABLE [core].[link_kunde_zaehlpunkt]
(
    [id_link_messeinheit] [sys].[int] NOT NULL,
    [id_mandant] [sys].[int] NOT NULL,
    [id_zp] [sys].[int] NOT NULL,
    [id_kunde] [sys].[int] NOT NULL,
    [valid_from] [sys].[date] CONSTRAINT [DF__link_kund__valid__357E9D96] DEFAULT (CONVERT([datetime],'01.01.1900',(104))) NOT NULL,
    [valid_to] [sys].[date] CONSTRAINT [DF__link_kund__valid__3672C1CF] DEFAULT (CONVERT([datetime],'31.12.9999',(104))) NULL,
    [id_status] [sys].[int] NULL,
    [status] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [id_lieferant] [sys].[int] NULL,
    [wandlerfaktor] decimal(10,3) NULL,
    [id_vertragsart] [sys].[int] NULL,
    [vertragsart] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [jahresverbrauch] decimal(15,3) NULL,
    [created_at] [sys].[date] CONSTRAINT [DF__link_kund__creat__33965524] DEFAULT (getdate()) NULL,
    [changed_at] [sys].[date] CONSTRAINT [DF__link_kund__chang__348A795D] DEFAULT (getdate()) NULL,
    [active] [sys].[int] CONSTRAINT [DF__link_kund__activ__3766E608] DEFAULT ((1)) NOT NULL,
    [id_vertrag] [sys].[int] CONSTRAINT [DF__link_kund__id_ve__06E6D79A] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [pk_link_kunde_zaehlpunkt] PRIMARY KEY CLUSTERED ([id_link_messeinheit] ASC)
);

ALTER TABLE [core].[link_kunde_zaehlpunkt]
ADD CONSTRAINT [fk_link_kunde_zaehlpunkt_lieferant]
FOREIGN KEY ([id_lieferant])
REFERENCES [core].[lieferanten] ([id_lieferant]);

ALTER TABLE [core].[link_kunde_zaehlpunkt]
ADD CONSTRAINT [fk_link_kunde_zaehlpunkt_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);

ALTER TABLE [core].[link_kunde_zaehlpunkt]
ADD CONSTRAINT [fk_link_kunde_zaehlpunkt_vertrag]
FOREIGN KEY ([id_vertrag])
REFERENCES [core].[vertraege] ([id_vertrag]);

ALTER TABLE [core].[link_kunde_zaehlpunkt]
ADD CONSTRAINT [fk_link_kunde_zaehlpunkt_zp]
FOREIGN KEY ([id_zp])
REFERENCES [core].[zaehlpunkte] ([id_zp]);

CREATE NONCLUSTERED INDEX [ix_link_kunde_zaehlpunkt_mandant_valid_from]
ON [core].[link_kunde_zaehlpunkt] ([id_mandant] ASC, [valid_from] ASC, [valid_to] ASC, [id_vertragsart] ASC)
INCLUDE ([id_zp], [id_kunde], [id_vertrag]);