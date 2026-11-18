CREATE TABLE [raw].[wilken_enzpn]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [ZPN_ID] decimal(12,0) NOT NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [ZPT_ID] decimal(12,0) NOT NULL,
    [ZPN_GUELTIGAB] [sys].[datetime] NOT NULL,
    [NET_ID] decimal(12,0) NOT NULL,
    [ZPN_ANGELEGT] [sys].[datetime] NOT NULL,
    [ZPN_GEAENDERT] [sys].[datetime] NULL,
    [ZPN_ANGELEGTUSR_ID] decimal(5,0) NULL,
    [ZPN_ANGELEGTDBUSER] varchar(30) COLLATE Latin1_General_CI_AS NULL
);