CREATE TABLE [core].[lokationsbuendel]
(
    [id_lokationsbuendel_element] [sys].[int] NOT NULL,
    [id_lokationsbuendel_zeitscheibe] [sys].[int] NOT NULL,
    [id_lokationsbuendel] [sys].[int] NOT NULL,
    [lokationsbuendel] varchar(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [lokationsbuendel_info] varchar(100) COLLATE Latin1_General_CI_AS NULL,
    [id_lokationsbuendelstruktur] [sys].[int] NOT NULL,
    [id_mandant] [sys].[int] CONSTRAINT [DF__lokations__id_ma__601689AF] DEFAULT ((1)) NOT NULL,
    [id_abn] [sys].[int] NOT NULL,
    [id_netzlokation] [sys].[int] NULL,
    [netzlokation] varchar(17) COLLATE Latin1_General_CI_AS NULL,
    [id_zp] [sys].[int] NULL,
    [id_malo_bezug] [sys].[int] NULL,
    [id_malo_einspeisung] [sys].[int] NULL,
    [id_ressource] [sys].[int] CONSTRAINT [DF__lokations__id_re__610AADE8] DEFAULT ((0)) NOT NULL,
    [id_melofunktion] [sys].[int] NOT NULL,
    [melofunktion] varchar(25) COLLATE Latin1_General_CI_AS NOT NULL,
    [id_ebene] [sys].[int] NOT NULL,
    [id_richtung] [sys].[int] NOT NULL,
    [richtung] varchar(25) COLLATE Latin1_General_CI_AS NOT NULL,
    [gueltig_ab] [sys].[date] NOT NULL,
    [gueltig_bis] [sys].[date] NOT NULL,
    [id_lokationsbuendel_status] [sys].[int] NOT NULL,
    [lokationsbuendel_status] varchar(9) COLLATE Latin1_General_CI_AS NOT NULL,
    [created_at] [sys].[date] CONSTRAINT [DF__lokations__creat__61FED221] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[date] CONSTRAINT [DF__lokations__chang__62F2F65A] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_lokationsbuendel] PRIMARY KEY CLUSTERED ([id_lokationsbuendel_element] ASC, [id_ressource] ASC)
);

ALTER TABLE [core].[lokationsbuendel]
ADD CONSTRAINT [fk_lokationsbuendel_struktur]
FOREIGN KEY ([id_lokationsbuendelstruktur])
REFERENCES [core].[lokationsbuendelstruktur] ([id_lokationsbuendelstruktur]);

ALTER TABLE [core].[lokationsbuendel]
ADD CONSTRAINT [fk_lokationsbuendel_zp]
FOREIGN KEY ([id_zp])
REFERENCES [core].[zaehlpunkte] ([id_zp]);