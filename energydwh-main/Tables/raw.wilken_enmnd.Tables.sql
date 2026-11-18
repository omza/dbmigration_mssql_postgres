CREATE TABLE [raw].[wilken_enmnd]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [MND_NAME] varchar(40) COLLATE Latin1_General_CI_AS NOT NULL,
    [MND_KONZERN] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [MND_GPMANDANT] char(2) COLLATE Latin1_General_CI_AS NOT NULL,
    [MND_ART_UNBUNDLING] decimal(1,0) NOT NULL,
    [MND_ART_VERTRIEB] decimal(1,0) NULL,
    [MND_STATUS] decimal(1,0) NULL,
    [MND_ANGELEGT] [sys].[datetime] NOT NULL,
    [MND_GEAENDERT] [sys].[datetime] NULL,
    [MND_ANGELEGTUSR_ID] decimal(5,0) NULL,
    [MND_ANGELEGTDBUSER] varchar(30) COLLATE Latin1_General_CI_AS NULL
);