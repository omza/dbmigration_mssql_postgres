CREATE TABLE [core].[technische_ressourcen]
(
    [id_mandant] [sys].[int] NOT NULL,
    [id_ressource] [sys].[int] NOT NULL,
    [ressourcen_nummer] varchar(20) COLLATE Latin1_General_CI_AS NOT NULL,
    [id_abn] [sys].[int] NOT NULL,
    [id_zp] [sys].[int] NULL,
    [id_malo_bezug] [sys].[int] NULL,
    [id_malo_einspeisung] [sys].[int] NULL,
    [ressource_nutzungsart] varchar(9) COLLATE Latin1_General_CI_AS NULL,
    [ressource_bemerkung] varchar(255) COLLATE Latin1_General_CI_AS NULL,
    [ressource_erzeugungsart] varchar(8) COLLATE Latin1_General_CI_AS NULL,
    [nennleistung_kw_abgabe] decimal(12,3) NULL,
    [nennleistung_kw_aufnahme] decimal(12,3) NULL,
    [speicherkapazitaet_kwh] decimal(18,3) NULL,
    [stromverbrauchsart] varchar(80) COLLATE Latin1_General_CI_AS NULL,
    [waermenutzung] varchar(80) COLLATE Latin1_General_CI_AS NULL,
    [faellt_unter_enwg14a] decimal(1,0) NULL,
    [inbetriebnahme_nach_2023] decimal(1,0) NULL,
    [einordnung_enwg_vor2024] varchar(30) COLLATE Latin1_General_CI_AS NULL,
    [weitere_technische_einrichtungen] decimal(1,0) NULL,
    [ressource_gueltig_ab] [sys].[date] NOT NULL,
    [ressource_gueltig_bis] [sys].[date] NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__technisch__creat__661B1276] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__technisch__chang__670F36AF] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_technische_ressourcen] PRIMARY KEY CLUSTERED ([id_ressource] ASC)
);

ALTER TABLE [core].[technische_ressourcen]
ADD CONSTRAINT [fk_tressource_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);

ALTER TABLE [core].[technische_ressourcen]
ADD CONSTRAINT [fk_tressource_zp]
FOREIGN KEY ([id_zp])
REFERENCES [core].[zaehlpunkte] ([id_zp]);