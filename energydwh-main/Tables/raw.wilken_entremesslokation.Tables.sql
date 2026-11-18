CREATE TABLE [raw].[wilken_entremesslokation]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [TRME_ID] decimal(12,0) NOT NULL,
    [TRE_ID] decimal(12,0) NOT NULL,
    [TRME_GUELTIGAB] [sys].[datetime] NOT NULL,
    [TRME_GUELTIGBIS] [sys].[datetime] NULL,
    [ZPT_ID] decimal(12,0) NOT NULL,
    [TRME_ANGELEGT] [sys].[datetime] NOT NULL,
    [TRME_GEAENDERT] [sys].[datetime] NULL
);