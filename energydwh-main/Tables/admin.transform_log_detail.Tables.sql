CREATE TABLE [admin].[transform_log_detail]
(
    [transform_job_id] [sys].[bigint] NOT NULL,
    [transform_timestamp] [sys].[datetime] CONSTRAINT [DF__transform__trans__71FCD09A] DEFAULT (getdate()) NOT NULL,
    [transform_routine] varchar(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [transform_message] varchar(MAX) COLLATE Latin1_General_CI_AS NULL
);