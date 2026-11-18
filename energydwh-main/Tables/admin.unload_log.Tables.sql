CREATE TABLE [admin].[unload_log]
(
    [unload_id] [sys].[bigint] IDENTITY(1,1) NOT NULL,
    [unload_job] varchar(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [unload_start_at] [sys].[datetime] NOT NULL,
    [unload_end_at] [sys].[datetime] NULL,
    [unload_status] [sys].[tinyint] CONSTRAINT [DF__unload_lo__unloa__2DB2C50F] DEFAULT ((0)) NOT NULL,
    [unload_message] varchar(MAX) COLLATE Latin1_General_CI_AS NULL,
    [src_query] varchar(MAX) COLLATE Latin1_General_CI_AS NULL,
    [src_rows_read] [sys].[bigint] NULL,
    [destination] varchar(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [recipient] varchar(100) COLLATE Latin1_General_CI_AS NULL,
    CONSTRAINT [pk_unload_log] PRIMARY KEY CLUSTERED ([unload_id] ASC)
);