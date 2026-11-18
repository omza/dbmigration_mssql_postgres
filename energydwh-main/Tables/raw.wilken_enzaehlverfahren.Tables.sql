CREATE TABLE [raw].[wilken_enzaehlverfahren]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [ZVF_NR] decimal(5,0) NOT NULL,
    [ZVF_BEZEICHNUNG] varchar(60) COLLATE Latin1_General_CI_AS NOT NULL,
    [ZVF_EDICODE] varchar(3) COLLATE Latin1_General_CI_AS NULL,
    [ZVF_ANGELEGT] [sys].[datetime] NOT NULL,
    [ZVF_GEAENDERT] [sys].[datetime] NULL,
    [ENE_ID] decimal(2,0) NOT NULL
);