CREATE TABLE [admin].[load_log]
(
    [load_id] [sys].[bigint] IDENTITY(1,1) NOT NULL,
    [load_type] varchar(10) COLLATE Latin1_General_CI_AS NOT NULL,
    [load_start_at] [sys].[datetime] NOT NULL,
    [load_end_at] [sys].[datetime] NULL,
    [load_status] [sys].[tinyint] CONSTRAINT [DF__load_log__load_s__6816A109] DEFAULT ((0)) NOT NULL,
    [load_message] varchar(500) COLLATE Latin1_General_CI_AS NULL,
    [src_query] varchar(MAX) COLLATE Latin1_General_CI_AS NULL,
    [src_rows_read] [sys].[bigint] NULL,
    [dest_table] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [dest_rows_written] [sys].[bigint] NULL,
    [dest_rows_inserted] [sys].[bigint] NULL,
    [dest_rows_updated] [sys].[bigint] NULL,
    [dest_rows_deleted] [sys].[bigint] NULL,
    [dest_rows_rejected] [sys].[bigint] NULL,
    CONSTRAINT [pk_load_log] PRIMARY KEY CLUSTERED ([load_id] ASC)
);