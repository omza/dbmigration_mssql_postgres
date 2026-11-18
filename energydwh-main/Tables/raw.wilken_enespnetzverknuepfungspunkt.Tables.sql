CREATE TABLE [raw].[wilken_enespnetzverknuepfungspunkt]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [ENVP_ID] decimal(12,0) NOT NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [ENVP_BEZEICHNUNG] varchar(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [ENVP_ANGELEGT] [sys].[datetime] NOT NULL,
    [ENVP_GEAENDERT] [sys].[datetime] NULL,
    [ENVP_MASTRNR_SAN] varchar(15) COLLATE Latin1_General_CI_AS NULL
);