CREATE TABLE [raw].[idoit_relationships]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [id_ebene] [sys].[int] NOT NULL,
    [id_parent] [sys].[int] NOT NULL,
    [id] varchar(10) COLLATE Latin1_General_CI_AS NULL,
    [sysid] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [type] varchar(50) COLLATE Latin1_General_CI_AS NULL
);