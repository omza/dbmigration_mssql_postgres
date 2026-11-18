CREATE TABLE [raw].[wilken_crena]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [ENA_ID] decimal(12,0) NOT NULL,
    [ENA_NR] decimal(2,0) NOT NULL,
    [ENA_KONZERN] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [ENA_BEZEICHNUNG] varchar(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [ENA_ENERGIEARTTYP] decimal(1,0) NOT NULL,
    [ENA_ANGELEGT] [sys].[datetime] NOT NULL,
    [ENA_GEAENDERT] [sys].[datetime] NULL,
    [ENA_ANGELEGTUSR_ID] decimal(5,0) NULL,
    [ENA_ANGELEGTDBUSER] varchar(30) COLLATE Latin1_General_CI_AS NULL
);