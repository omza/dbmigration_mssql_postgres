CREATE TABLE [raw].[wilken_enzptmlk]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [ZMLK_ID] decimal(12,0) NOT NULL,
    [ZPT_ID] decimal(12,0) NOT NULL,
    [MLK_ID] decimal(12,0) NOT NULL,
    [ZMLK_GUELTIGAB] [sys].[datetime] NOT NULL,
    [ZMLK_GUELTIGBIS] [sys].[datetime] NULL,
    [ZMLK_TYP] decimal(1,0) NOT NULL,
    [ZMLK_ANGELEGT] [sys].[datetime] NOT NULL,
    [ZMLK_GEAENDERT] [sys].[datetime] NULL
);