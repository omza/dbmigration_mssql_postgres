CREATE TABLE [mart_technische_doku].[caigos_nelos_wilken]
(
    [abnahmestelle_straße] varchar(70) COLLATE Latin1_General_CI_AS NOT NULL,
    [abnahmestelle_hausnummer] [sys].[int] NOT NULL,
    [abnahmestelle_hausnummer_zusatz] varchar(30) COLLATE Latin1_General_CI_AS NOT NULL,
    [abnahmestelle_plz] varchar(10) COLLATE Latin1_General_CI_AS NOT NULL,
    [abnahmestelle_ort] varchar(40) COLLATE Latin1_General_CI_AS NOT NULL,
    [nelo] varchar(17) COLLATE Latin1_General_CI_AS NOT NULL,
    [erstellt_am] [sys].[date] CONSTRAINT [DF__caigos_ne__erste__3E5EF97B] DEFAULT (getdate()) NOT NULL,
    [geaendert_am] [sys].[date] CONSTRAINT [DF__caigos_ne__geaen__3F531DB4] DEFAULT (getdate()) NOT NULL,
    [geloescht_am] [sys].[date] NULL,
    [delta] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [pflegehinweis] varchar(400) COLLATE Latin1_General_CI_AS NULL,
    [eha_id] varchar(38) COLLATE Latin1_General_CI_AS NULL,
    CONSTRAINT [pk_caigos_nelos_wilken] PRIMARY KEY CLUSTERED ([nelo] ASC)
);