CREATE TABLE [mart_energievertrieb].[fact_rlmkunden_lastgangversand]
(
    [jahr] [sys].[int] NOT NULL,
    [monat] [sys].[int] NOT NULL,
    [meteringcode] varchar(33) COLLATE Latin1_General_CI_AS NOT NULL,
    [versand_am] [sys].[date] NULL,
    [fehler_am] [sys].[date] NULL,
    [fehler] varchar(100) COLLATE Latin1_General_CI_AS NULL,
    [nachgehakt_am] [sys].[datetime] NULL,
    CONSTRAINT [pk_fact_rlmkunden_lastgangversand] PRIMARY KEY CLUSTERED ([jahr] ASC, [monat] ASC, [meteringcode] ASC)
);