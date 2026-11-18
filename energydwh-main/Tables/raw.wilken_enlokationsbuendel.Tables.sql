CREATE TABLE [raw].[wilken_enlokationsbuendel]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [LOKB_ID] decimal(12,0) NOT NULL,
    [ABN_ID] decimal(12,0) NOT NULL,
    [LOKB_BEZEICHNUNG] varchar(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [LOKB_STRUKTURCODE] varchar(20) COLLATE Latin1_General_CI_AS NOT NULL,
    [LOKB_INFO] varchar(1000) COLLATE Latin1_General_CI_AS NULL,
    [LOKB_ANGELEGT] [sys].[datetime] NOT NULL,
    [LOKB_GEAENDERT] [sys].[datetime] NULL,
    [LOKB_ANGELEGTUSR_ID] decimal(5,0) NULL,
    [LOKB_ANGELEGTDBUSER] varchar(30) COLLATE Latin1_General_CI_AS NULL
);