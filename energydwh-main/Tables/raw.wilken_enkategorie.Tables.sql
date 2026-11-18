CREATE TABLE [raw].[wilken_enkategorie]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [KAT_NR] char(3) COLLATE Latin1_General_CI_AS NOT NULL,
    [KAT_BEZEICHNUNG] varchar(40) COLLATE Latin1_General_CI_AS NOT NULL,
    [KAT_AKTIV] char(1) COLLATE Latin1_General_CI_AS NOT NULL
);