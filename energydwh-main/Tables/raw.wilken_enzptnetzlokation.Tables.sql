CREATE TABLE [raw].[wilken_enzptnetzlokation]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [ZNLK_ID] decimal(12,0) NOT NULL,
    [ZPT_ID] decimal(12,0) NOT NULL,
    [NLK_ID] decimal(12,0) NOT NULL,
    [ZNLK_GUELTIGAB] [sys].[datetime] NOT NULL,
    [ZNLK_GUELTIGBIS] [sys].[datetime] NULL,
    [ZNLK_ANGELEGT] [sys].[datetime] NOT NULL,
    [ZNLK_GEAENDERT] [sys].[datetime] NULL,
    [ZNLK_ANGELEGTUSR_ID] decimal(5,0) NULL,
    [ZNLK_ANGELEGTDBUSER] varchar(30) COLLATE Latin1_General_CI_AS NULL
);