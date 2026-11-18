CREATE TABLE [raw].[wilken_enzaenenngroesse]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [ZNE_NR] decimal(3,0) NOT NULL,
    [ZNE_BEZEICHNUNG] varchar(40) COLLATE Latin1_General_CI_AS NOT NULL,
    [ENE_ID] decimal(2,0) NOT NULL
);