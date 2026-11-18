CREATE TABLE [admin].[transform_log]
(
    [load_id] [sys].[bigint] NOT NULL,
    [transform_job_id] [sys].[bigint] CONSTRAINT [DF__transform__trans__627A95E8] DEFAULT ((-1)) NOT NULL,
    [transform_source] nvarchar(1000) COLLATE Latin1_General_CI_AS NOT NULL,
    [transform_triggered_at] [sys].[datetime] CONSTRAINT [DF__transform__trans__618671AF] DEFAULT (getdate()) NOT NULL,
    [transform_start_at] [sys].[datetime] NULL,
    [transform_end_at] [sys].[datetime] NULL,
    [transform_status] [sys].[tinyint] CONSTRAINT [DF__transform__trans__636EBA21] DEFAULT ((0)) NOT NULL,
    [transform_message] nvarchar(500) COLLATE Latin1_General_CI_AS NULL
);