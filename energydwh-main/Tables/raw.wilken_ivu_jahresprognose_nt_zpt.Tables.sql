CREATE TABLE [raw].[wilken_ivu_jahresprognose_nt_zpt]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [ZPT_ID] decimal(12,0) NOT NULL,
    [PROG_BEGINN] [sys].[datetime] NOT NULL,
    [PROG_ENDE] [sys].[datetime] NOT NULL,
    [JAHRESPROGNOSE] decimal(20,10) NULL
);