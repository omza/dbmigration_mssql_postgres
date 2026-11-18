CREATE TABLE [core].[einspeiseanlagen]
(
    [id_einspeiseanlage] [sys].[int] NOT NULL,
    [id_mandant] [sys].[int] NOT NULL,
    [id_zp] [sys].[int] NULL,
    [id_zp_einspeisezaehlpunkt] [sys].[int] NULL,
    [einspeisezaehlpunkt_gueltig_ab] [sys].[date] NULL,
    [id_abn] [sys].[int] NOT NULL,
    [einspeiseanlage] varchar(33) COLLATE Latin1_General_CI_AS NOT NULL,
    [energietraeger] varchar(40) COLLATE Latin1_General_CI_AS NOT NULL,
    [id_status] [sys].[int] NOT NULL,
    [status] varchar(32) COLLATE Latin1_General_CI_AS NOT NULL,
    [storniert_am] [sys].[date] NULL,
    [id_einspeiseart] [sys].[int] NOT NULL,
    [einspeiseart] varchar(24) COLLATE Latin1_General_CI_AS NOT NULL,
    [einspeiseanlage_aenderungstyp] varchar(15) COLLATE Latin1_General_CI_AS NULL,
    [installierte_leistung] decimal(12,3) NULL,
    [bnetza_eeg_schluessel] varchar(33) COLLATE Latin1_General_CI_AS NULL,
    [bnetzameldedatum] [sys].[date] NULL,
    [bnetza_aso_nr] varchar(20) COLLATE Latin1_General_CI_AS NULL,
    [marktstammdatenregister_nummer] varchar(20) COLLATE Latin1_General_CI_AS NULL,
    [marktstammdatenregister_registriert_am] [sys].[date] NULL,
    [id_nvp] [sys].[int] NULL,
    [netzverknuepfungspunkt] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [nvp_gueltig_ab] [sys].[date] NULL,
    [inbetriebnahme] [sys].[date] NULL,
    [stilllegungsdatum] [sys].[date] NULL,
    [netzzugang] [sys].[date] NULL,
    [netzabgang] [sys].[date] NULL,
    [aufnahme_dauerbetrieb] [sys].[date] NULL,
    [stromerzeugungseinheit_mastnr_nummer] varchar(20) COLLATE Latin1_General_CI_AS NULL,
    [stromerzeugungseinheit_mastnr_registriert_am] [sys].[date] NULL,
    [stromerzeugungseinheit_gueltig_ab] [sys].[date] NULL,
    [id_ressource] [sys].[int] NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__einspeise__creat__41A8A7D6] DEFAULT (getdate()) NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__einspeise__chang__429CCC0F] DEFAULT (getdate()) NULL,
    CONSTRAINT [pk_einspeiseanlagen] PRIMARY KEY CLUSTERED ([id_einspeiseanlage] ASC)
);

ALTER TABLE [core].[einspeiseanlagen]
ADD CONSTRAINT [fk_einspeiseanlage_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);

ALTER TABLE [core].[einspeiseanlagen]
ADD CONSTRAINT [fk_einspeiseanlage_technische_ressource]
FOREIGN KEY ([id_ressource])
REFERENCES [core].[technische_ressourcen] ([id_ressource]);