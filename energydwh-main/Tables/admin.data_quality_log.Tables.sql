CREATE TABLE [admin].[data_quality_log]
(
    [dqm_job] varchar(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [system] varchar(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [domain] varchar(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [object] varchar(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [failure] varchar(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [count_rows] [sys].[int] NOT NULL,
    [datum] [sys].[date] NOT NULL,
    CONSTRAINT [pk_data_quality_log] PRIMARY KEY CLUSTERED ([system] ASC, [domain] ASC, [object] ASC, [failure] ASC, [datum] ASC)
);