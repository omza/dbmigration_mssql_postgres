CREATE TABLE [raw].[wilken_entechnischeressource]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [TRE_ID] decimal(12,0) NOT NULL,
    [TRE_BEMERKUNG] varchar(255) COLLATE Latin1_General_CI_AS NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [TRE_TR_ID] varchar(11) COLLATE Latin1_General_CI_AS NOT NULL,
    [TRE_ANGELEGT] [sys].[datetime] NOT NULL,
    [TRE_GEAENDERT] [sys].[datetime] NULL,
    [TRE_BEGINN] [sys].[datetime] NOT NULL,
    [TRE_ENDE] [sys].[datetime] NULL,
    [ABN_ID] decimal(12,0) NOT NULL
);