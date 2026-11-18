CREATE TABLE [core].[zaehlpunkte]
(
    [id_zp] [sys].[int] NOT NULL,
    [id_mandant] [sys].[int] NULL,
    [wilken_zpt_id] [sys].[int] NOT NULL,
    [meteringcode] nvarchar(33) COLLATE Latin1_General_CI_AS NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [id_zp_typ] [sys].[int] NOT NULL,
    [abnahmestelle_adresse] varchar(204) COLLATE Latin1_General_CI_AS NULL,
    [ablesetour_nr] decimal(5,0) NULL,
    [wilken_brw_nr] char(3) COLLATE Latin1_General_CI_AS NULL,
    [wilken_zpt_ismesslokation] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [wilken_zpt_komplexemessung] char(1) COLLATE Latin1_General_CI_AS NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__zaehlpunk__creat__6D031153] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__zaehlpunk__chang__6DF7358C] DEFAULT (getdate()) NULL,
    [abnahmestelle_straße] varchar(70) COLLATE Latin1_General_CI_AS NULL,
    [abnahmestelle_hausnummer] [sys].[int] NULL,
    [abnahmestelle_hausnummer_zusatz] varchar(30) COLLATE Latin1_General_CI_AS NULL,
    [abnahmestelle_plz] varchar(10) COLLATE Latin1_General_CI_AS NULL,
    [abnahmestelle_ort] varchar(40) COLLATE Latin1_General_CI_AS NULL,
    [abnahmestelle_lat] decimal(11,8) NULL,
    [abnahmestelle_lon] decimal(11,8) NULL,
    [abnahmestelle_location_type] varchar(20) COLLATE Latin1_General_CI_AS NULL,
    [id_abn] [sys].[int] CONSTRAINT [DF__zaehlpunk__id_ab__4BC611CC] DEFAULT ((0)) NOT NULL,
    [id_netz] [sys].[int] CONSTRAINT [DF__zaehlpunk__id_ne__4CBA3605] DEFAULT ((45428123)) NOT NULL,
    [abnahmestelle_status] [sys].[int] CONSTRAINT [DF__zaehlpunk__abnah__55390889] DEFAULT ((-1)) NOT NULL,
    [id_spannungsebene] [sys].[int] CONSTRAINT [DF__zaehlpunk__id_sp__17FAF01F] DEFAULT ((-1)) NOT NULL,
    [id_spannungsebene_messung] [sys].[int] NULL,
    [anschlussleistung] decimal(12,3) NULL,
    [installierte_leistung] decimal(12,3) NULL,
    [gasdruck_mbar] [sys].[int] NULL,
    [id_lastprofil] [sys].[int] CONSTRAINT [DF__zaehlpunk__id_la__2E3F36F9] DEFAULT ((-1)) NOT NULL,
    [id_zaehlverfahren] [sys].[int] CONSTRAINT [DF__zaehlpunk__id_za__2F335B32] DEFAULT ((-1)) NOT NULL,
    [id_messstellenbetreiber] [sys].[int] CONSTRAINT [DF__zaehlpunk__id_me__51D422A7] DEFAULT ((-1)) NOT NULL,
    [grundzustaendig_messstellenbetreiber] [sys].[int] CONSTRAINT [DF__zaehlpunk__grund__52C846E0] DEFAULT ((-1)) NOT NULL,
    CONSTRAINT [pk_zaehlpunkte] PRIMARY KEY CLUSTERED ([id_zp] ASC)
);

ALTER TABLE [core].[zaehlpunkte]
ADD CONSTRAINT [fk_zp_energiearten]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);

ALTER TABLE [core].[zaehlpunkte]
ADD CONSTRAINT [fk_zp_lastprofil]
FOREIGN KEY ([id_lastprofil])
REFERENCES [core].[lastprofile] ([id_lastprofil]);

ALTER TABLE [core].[zaehlpunkte]
ADD CONSTRAINT [fk_zp_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);

ALTER TABLE [core].[zaehlpunkte]
ADD CONSTRAINT [fk_zp_messstellenbetreiber]
FOREIGN KEY ([id_messstellenbetreiber])
REFERENCES [core].[messstellenbetreiber] ([id_messstellenbetreiber]);

ALTER TABLE [core].[zaehlpunkte]
ADD CONSTRAINT [fk_zp_netz]
FOREIGN KEY ([id_netz])
REFERENCES [core].[netze] ([id_netz]);

ALTER TABLE [core].[zaehlpunkte]
ADD CONSTRAINT [fk_zp_spannungsebene]
FOREIGN KEY ([id_spannungsebene], [id_mandant])
REFERENCES [core].[spannungsebenen] ([id_spannungsebene], [id_mandant]);

ALTER TABLE [core].[zaehlpunkte]
ADD CONSTRAINT [fk_zp_zaehlverfahren]
FOREIGN KEY ([id_mandant], [id_zaehlverfahren])
REFERENCES [core].[zaehlverfahren] ([id_mandant], [id_zaehlverfahren]);

ALTER TABLE [core].[zaehlpunkte]
ADD CONSTRAINT [fk_zp_zp_typ]
FOREIGN KEY ([id_zp_typ])
REFERENCES [core].[zaehlpunkt_typen] ([id_zp_typ]);