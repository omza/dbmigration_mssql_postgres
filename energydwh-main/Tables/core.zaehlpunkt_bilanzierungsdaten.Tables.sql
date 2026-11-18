CREATE TABLE [core].[zaehlpunkt_bilanzierungsdaten]
(
    [id_zp] [sys].[int] NOT NULL,
    [id_mandant] [sys].[int] NOT NULL,
    [gueltig_ab] [sys].[date] NOT NULL,
    [gueltig_bis] [sys].[date] NOT NULL,
    [id_zaehlverfahren] [sys].[int] NOT NULL,
    [id_lastprofil] [sys].[int] NOT NULL,
    [jahresentnahme_kwh] decimal(16,3) NULL,
    [id_bilanzierungsgebiet] [sys].[int] NULL,
    [messtechnik_malo] varchar(15) COLLATE Latin1_General_CI_AS NULL,
    [id_prognosegrundlage] [sys].[int] NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__zaehlpunk__creat__7F31A45A] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__zaehlpunk__chang__0025C893] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_zaehlpunkt_bilanzierungsdaten] PRIMARY KEY CLUSTERED ([id_zp] ASC, [gueltig_ab] ASC)
);

ALTER TABLE [core].[zaehlpunkt_bilanzierungsdaten]
ADD CONSTRAINT [fk_zpbiladaten_lastprofil]
FOREIGN KEY ([id_lastprofil])
REFERENCES [core].[lastprofile] ([id_lastprofil]);

ALTER TABLE [core].[zaehlpunkt_bilanzierungsdaten]
ADD CONSTRAINT [fk_zpbiladaten_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);

ALTER TABLE [core].[zaehlpunkt_bilanzierungsdaten]
ADD CONSTRAINT [fk_zpbiladaten_zaehlpunkt]
FOREIGN KEY ([id_zp])
REFERENCES [core].[zaehlpunkte] ([id_zp]);

ALTER TABLE [core].[zaehlpunkt_bilanzierungsdaten]
ADD CONSTRAINT [fk_zpbiladaten_zaehlverfahren]
FOREIGN KEY ([id_mandant], [id_zaehlverfahren])
REFERENCES [core].[zaehlverfahren] ([id_mandant], [id_zaehlverfahren]);