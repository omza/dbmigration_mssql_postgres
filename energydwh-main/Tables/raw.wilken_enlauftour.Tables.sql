CREATE TABLE [raw].[wilken_enlauftour]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [LTO_NR] decimal(5,0) NOT NULL,
    [LTO_BEZEICHNUNG] varchar(100) COLLATE Latin1_General_CI_AS NULL,
    [LTO_SONDERTOUR] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [LTO_BELVISTOUR] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [LTO_GANGFOLGE_PFLICHT] decimal(1,0) NULL
);