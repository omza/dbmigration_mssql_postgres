CREATE TABLE [raw].[nedi_interfaces]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [device] varchar(64) COLLATE Latin1_General_CI_AS NOT NULL,
    [ifname] varchar(32) COLLATE Latin1_General_CI_AS NOT NULL,
    [ifdesc] varchar(255) COLLATE Latin1_General_CI_AS NULL,
    [ifstat] [sys].[smallint] NULL
);