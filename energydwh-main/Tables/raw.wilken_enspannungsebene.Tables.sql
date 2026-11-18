CREATE TABLE [raw].[wilken_enspannungsebene]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [SPE_NR] decimal(5,0) NOT NULL,
    [SPE_BEZEICHNUNG] varchar(40) COLLATE Latin1_General_CI_AS NOT NULL,
    [SPE_EDICODE] varchar(3) COLLATE Latin1_General_CI_AS NULL,
    [SPE_KZ_ENTNAHME] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [SPE_KZ_MESSUNG] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [SPE_ANGELEGT] [sys].[datetime] NOT NULL,
    [SPE_GEAENDERT] [sys].[datetime] NULL,
    [ENE_ID] decimal(2,0) NOT NULL
);