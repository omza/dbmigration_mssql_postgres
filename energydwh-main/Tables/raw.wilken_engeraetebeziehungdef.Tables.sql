CREATE TABLE [raw].[wilken_engeraetebeziehungdef]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [GBZD_ID] decimal(12,0) NOT NULL,
    [GBZD_BEZEICHNUNG] varchar(40) COLLATE Latin1_General_CI_AS NOT NULL,
    [GER_ID_MASTER] decimal(12,0) NOT NULL,
    [GER_ID_SLAVE] decimal(12,0) NOT NULL,
    [GBZD_ANGELEGT] [sys].[datetime] NOT NULL,
    [GBZD_GEAENDERT] [sys].[datetime] NULL
);