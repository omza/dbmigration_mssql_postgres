CREATE TABLE [core].[zaehlpunkt_jahresverbraeuche_abgerechnet]
(
    [id_link_messeinheit] [sys].[int] NOT NULL,
    [id_zp] [sys].[int] NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [Jahresverbrauch_kwh_gesamt] decimal(16,3) NOT NULL,
    [Jahresverbrauch_kwh_nt] decimal(16,3) NOT NULL,
    [gueltig_von] [sys].[date] NOT NULL,
    [gueltig_bis] [sys].[date] NOT NULL,
    [abgerechnete_tage] [sys].[int] NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__zaehlpunk__creat__26807BA5] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__zaehlpunk__chang__27749FDE] DEFAULT (getdate()) NOT NULL,
    [messeinheit_letzte_zeitscheibe] [sys].[tinyint] CONSTRAINT [DF__zaehlpunk__messe__5229F3B9] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [pk_zaehlpunkt_jahresverbraeuche_abgerechnet] PRIMARY KEY CLUSTERED ([id_zp] ASC, [gueltig_von] ASC)
);

ALTER TABLE [core].[zaehlpunkt_jahresverbraeuche_abgerechnet]
ADD CONSTRAINT [fk_zpjvabgerechnet_energieart]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);

ALTER TABLE [core].[zaehlpunkt_jahresverbraeuche_abgerechnet]
ADD CONSTRAINT [fk_zpjvabgerechnet_messeinheit]
FOREIGN KEY ([id_link_messeinheit])
REFERENCES [core].[link_kunde_zaehlpunkt] ([id_link_messeinheit]);

ALTER TABLE [core].[zaehlpunkt_jahresverbraeuche_abgerechnet]
ADD CONSTRAINT [fk_zpjvabgerechnet_zaehlpunkt]
FOREIGN KEY ([id_zp])
REFERENCES [core].[zaehlpunkte] ([id_zp]);

CREATE UNIQUE NONCLUSTERED INDEX [unique_zpjvabgerechnet_mesid]
ON [core].[zaehlpunkt_jahresverbraeuche_abgerechnet] ([id_link_messeinheit] ASC, [gueltig_von] ASC);