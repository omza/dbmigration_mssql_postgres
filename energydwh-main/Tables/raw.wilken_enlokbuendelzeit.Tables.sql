CREATE TABLE [raw].[wilken_enlokbuendelzeit]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [LOKBZ_ID] decimal(12,0) NOT NULL,
    [LOKB_ID] decimal(12,0) NOT NULL,
    [LOKBZ_GUELTIGAB] [sys].[datetime] NOT NULL,
    [LOKBZ_GUELTIGBIS] [sys].[datetime] NULL,
    [LOKBZ_STATUS] decimal(1,0) NOT NULL,
    [LOKBZ_ANGELEGT] [sys].[datetime] NOT NULL,
    [LOKBZ_GEAENDERT] [sys].[datetime] NULL,
    [LOKBZ_ANGELEGTUSR_ID] decimal(5,0) NULL,
    [LOKBZ_ANGELEGTDBUSER] varchar(30) COLLATE Latin1_General_CI_AS NULL
);