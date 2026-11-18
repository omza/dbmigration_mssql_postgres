CREATE TABLE [raw].[wilken_edwaen]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [WAEN_NR] decimal(5,0) NOT NULL,
    [WAEN_EDICODE] varchar(3) COLLATE Latin1_General_CI_AS NOT NULL,
    [WAEN_BEZEICHNUNG] varchar(80) COLLATE Latin1_General_CI_AS NULL,
    [WAEN_GEAENDERT] [sys].[datetime] NULL,
    [WAEN_ANGELEGT] [sys].[datetime] NOT NULL,
    [WAEN_ANGELEGTUSR_ID] decimal(5,0) NULL,
    [WAEN_ANGELEGTDBUSER] varchar(30) COLLATE Latin1_General_CI_AS NULL
);