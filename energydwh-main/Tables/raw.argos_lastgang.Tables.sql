CREATE TABLE [raw].[argos_lastgang]
(
    [id] [sys].[bigint] IDENTITY(1,1) NOT NULL,
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [filename] varchar(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [Zeit] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Last] varchar(100) COLLATE Latin1_General_CI_AS NULL,
    [Status] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Status_Text] varchar(50) COLLATE Latin1_General_CI_AS NULL
);