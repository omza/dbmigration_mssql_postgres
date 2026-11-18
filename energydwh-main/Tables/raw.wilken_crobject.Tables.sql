CREATE TABLE [raw].[wilken_crobject]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [OBJ_NAME] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [ICN_ID] decimal(12,0) NULL,
    [OBJ_ANGELEGT] [sys].[datetime] NOT NULL,
    [OBJ_GEAENDERT] [sys].[datetime] NULL,
    [OBJ_TABLENAME] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [OBJ_DISPLAYSTRING] varchar(2000) COLLATE Latin1_General_CI_AS NULL,
    [OBJ_RELATION] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [OBJ_DESCRIPTION] varchar(400) COLLATE Latin1_General_CI_AS NULL,
    [OBJ_HINT] varchar(2000) COLLATE Latin1_General_CI_AS NULL,
    [OBJ_ACTIONGUID] varchar(200) COLLATE Latin1_General_CI_AS NOT NULL,
    [OBJ_PERMISSIONGUID] varchar(200) COLLATE Latin1_General_CI_AS NOT NULL,
    [OBJ_DISPLAYNAME] varchar(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [OBJ_VIRTUAL] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [OBJ_ID] decimal(12,0) NOT NULL,
    [OBJ_PROTOCOLL] char(1) COLLATE Latin1_General_CI_AS NULL
);