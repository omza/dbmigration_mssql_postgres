CREATE TABLE [raw].[power_switch_list_ipuep_saga]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [id] [sys].[int] NOT NULL,
    [device] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [type] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [status] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [location] varchar(MAX) COLLATE Latin1_General_CI_AS NULL
);