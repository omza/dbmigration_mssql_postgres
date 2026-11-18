CREATE TABLE [admin].[load_freshness]
(
    [schema] nvarchar(128) COLLATE Latin1_General_CI_AS NOT NULL,
    [dest_table] nvarchar(128) COLLATE Latin1_General_CI_AS NOT NULL,
    [max_load_at] [sys].[datetime] NULL,
    [last_load_id] [sys].[bigint] NULL,
    [last_load_at] [sys].[datetime] NULL,
    [last_load_status] [sys].[tinyint] NULL,
    [max_days_age] [sys].[int] NOT NULL,
    [freshness_ignore] [sys].[tinyint] NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__load_fres__creat__1918FFC0] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__load_fres__chang__1A0D23F9] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_load_freshness] PRIMARY KEY CLUSTERED ([dest_table] ASC)
);