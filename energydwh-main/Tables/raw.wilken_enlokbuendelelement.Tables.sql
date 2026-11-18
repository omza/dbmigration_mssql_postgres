CREATE TABLE [raw].[wilken_enlokbuendelelement]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [LOKBE_ID] decimal(12,0) NOT NULL,
    [LOKBZ_ID] decimal(12,0) NOT NULL,
    [LOKSO_ID] decimal(12,0) NOT NULL,
    [ZPT_ID_MELO] decimal(12,0) NULL,
    [MLK_ID] decimal(12,0) NULL,
    [NLK_ID] decimal(12,0) NULL,
    [TRE_ID] decimal(12,0) NULL,
    [LOKBE_ANGELEGT] [sys].[datetime] NOT NULL,
    [LOKBE_GEAENDERT] [sys].[datetime] NULL,
    [LOKBE_ANGELEGTUSR_ID] decimal(5,0) NULL,
    [LOKBE_ANGELEGTDBUSER] varchar(30) COLLATE Latin1_General_CI_AS NULL,
    [LOKBE_IDENTIFIKATIONSCODE] varchar(33) COLLATE Latin1_General_CI_AS NULL,
    [LOKBE_ZUGEORDNET] char(1) COLLATE Latin1_General_CI_AS NOT NULL
);