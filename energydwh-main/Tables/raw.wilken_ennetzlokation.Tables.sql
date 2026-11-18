CREATE TABLE [raw].[wilken_ennetzlokation]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [NLK_ID] decimal(12,0) NOT NULL,
    [NLK_CODE] varchar(17) COLLATE Latin1_General_CI_AS NOT NULL,
    [NLK_ZUSATZ] varchar(400) COLLATE Latin1_General_CI_AS NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [NLK_ANGELEGT] [sys].[datetime] NOT NULL,
    [NLK_GEAENDERT] [sys].[datetime] NULL,
    [NLK_ANGELEGTUSR_ID] decimal(5,0) NULL,
    [NLK_ANGELEGTDBUSER] varchar(30) COLLATE Latin1_General_CI_AS NULL
);