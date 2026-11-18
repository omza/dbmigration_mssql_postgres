CREATE TABLE [raw].[wilken_enzenr]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [ZENR_NR] decimal(5,0) NOT NULL,
    [ZENR_BEZEICHNUNG] varchar(40) COLLATE Latin1_General_CI_AS NOT NULL,
    [ZENR_EDICODE] varchar(3) COLLATE Latin1_General_CI_AS NOT NULL,
    [ZENR_ANGELEGT] [sys].[datetime] NOT NULL,
    [ZENR_GEAENDERT] [sys].[datetime] NULL
);