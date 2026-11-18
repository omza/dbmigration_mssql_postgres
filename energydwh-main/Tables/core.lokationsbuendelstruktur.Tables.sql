CREATE TABLE [core].[lokationsbuendelstruktur]
(
    [id_lokationsbuendelstruktur] [sys].[int] NOT NULL,
    [lokationsbuendelstruktur_code] varchar(20) COLLATE Latin1_General_CI_AS NOT NULL,
    [lokationsbuendelstruktur_bezeichnung] varchar(200) COLLATE Latin1_General_CI_AS NULL,
    [gueltig_ab] [sys].[date] NOT NULL,
    [gueltig_bis] [sys].[date] NOT NULL,
    [created_at] [sys].[date] CONSTRAINT [DF__lokations__creat__735E684D] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[date] CONSTRAINT [DF__lokations__chang__74528C86] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_lokationsbuendelstruktur] PRIMARY KEY CLUSTERED ([id_lokationsbuendelstruktur] ASC)
);