CREATE TABLE [raw].[idoit_objects]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [id] varchar(10) COLLATE Latin1_General_CI_AS NULL,
    [title] varchar(100) COLLATE Latin1_General_CI_AS NULL,
    [sysid] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [type] varchar(10) COLLATE Latin1_General_CI_AS NULL,
    [created] varchar(20) COLLATE Latin1_General_CI_AS NULL,
    [updated] varchar(20) COLLATE Latin1_General_CI_AS NULL,
    [type_title] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [type_group_title] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [status] varchar(5) COLLATE Latin1_General_CI_AS NULL,
    [cmdb_status] varchar(5) COLLATE Latin1_General_CI_AS NULL,
    [cmdb_status_title] varchar(50) COLLATE Latin1_General_CI_AS NULL
);