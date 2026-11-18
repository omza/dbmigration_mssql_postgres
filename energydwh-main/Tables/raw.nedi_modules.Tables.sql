CREATE TABLE [raw].[nedi_modules]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [device] varchar(64) COLLATE Latin1_General_CI_AS NOT NULL,
    [slot] varchar(64) COLLATE Latin1_General_CI_AS NULL,
    [model] varchar(64) COLLATE Latin1_General_CI_AS NULL,
    [moddesc] varchar(255) COLLATE Latin1_General_CI_AS NULL,
    [serial] varchar(32) COLLATE Latin1_General_CI_AS NULL,
    [hw] varchar(128) COLLATE Latin1_General_CI_AS NULL,
    [fw] varchar(128) COLLATE Latin1_General_CI_AS NULL,
    [sw] varchar(128) COLLATE Latin1_General_CI_AS NULL,
    [modidx] [sys].[bigint] NULL,
    [modclass] [sys].[smallint] NULL,
    [status] [sys].[int] NULL,
    [modloc] varchar(255) COLLATE Latin1_General_CI_AS NULL,
    [value1] [sys].[real] NULL,
    [value2] [sys].[real] NULL
);