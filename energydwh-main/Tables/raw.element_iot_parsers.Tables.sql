CREATE TABLE [raw].[element_iot_parsers]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [id] varchar(36) COLLATE Latin1_General_CI_AS NULL,
    [name] varchar(54) COLLATE Latin1_General_CI_AS NULL,
    [fields] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [updated_at] varchar(27) COLLATE Latin1_General_CI_AS NULL,
    [inserted_at] varchar(27) COLLATE Latin1_General_CI_AS NULL
);