CREATE TABLE [core].[produkte]
(
    [id_produkt] [sys].[int] NOT NULL,
    [id_produktvariante] [sys].[int] NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [id_produktart] [sys].[int] NOT NULL,
    [produkt_nummer] varchar(10) COLLATE Latin1_General_CI_AS NOT NULL,
    [produkt] varchar(40) COLLATE Latin1_General_CI_AS NOT NULL,
    [produkt_publikationsbezeichnung] varchar(40) COLLATE Latin1_General_CI_AS NULL,
    [variante_nummer] varchar(10) COLLATE Latin1_General_CI_AS NULL,
    [variante] varchar(40) COLLATE Latin1_General_CI_AS NULL,
    [variante_publikationsbezeichnung] varchar(40) COLLATE Latin1_General_CI_AS NULL,
    [gueltig_von] [sys].[date] NOT NULL,
    [gueltig_bis] [sys].[date] NOT NULL,
    [produkt_status] [sys].[int] NOT NULL,
    [variante_status] [sys].[int] NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__produkte__create__53673394] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__produkte__change__545B57CD] DEFAULT (getdate()) NULL,
    CONSTRAINT [pk_produkte] PRIMARY KEY CLUSTERED ([id_produkt] ASC, [id_produktvariante] ASC)
);

ALTER TABLE [core].[produkte]
ADD CONSTRAINT [fk_produkt_energieart]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);