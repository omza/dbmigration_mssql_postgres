CREATE TABLE [raw].[wilken_entremarktlokation]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [TRMA_ID] decimal(12,0) NOT NULL,
    [TRE_ID] decimal(12,0) NOT NULL,
    [TRMA_GUELTIGAB] [sys].[datetime] NOT NULL,
    [TRMA_GUELTIGBIS] [sys].[datetime] NULL,
    [TRMA_LIEFERRICHTUNG] decimal(1,0) NOT NULL,
    [TRMA_ANGELEGT] [sys].[datetime] NOT NULL,
    [TRMA_GEAENDERT] [sys].[datetime] NULL,
    [MLK_ID] decimal(12,0) NOT NULL,
    [TRMA_IS_TRANCHE] char(1) COLLATE Latin1_General_CI_AS NOT NULL
);