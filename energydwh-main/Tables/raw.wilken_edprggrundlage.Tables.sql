CREATE TABLE [raw].[wilken_edprggrundlage]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [PRGG_NR] decimal(5,0) NOT NULL,
    [PRGG_BEZEICHNUNG] varchar(100) COLLATE Latin1_General_CI_AS NULL,
    [PRGG_BASIS] varchar(3) COLLATE Latin1_General_CI_AS NOT NULL,
    [PRGG_EDICODE] varchar(3) COLLATE Latin1_General_CI_AS NULL,
    [PRGG_EDICODE2] varchar(3) COLLATE Latin1_General_CI_AS NULL,
    [EVK_ID_AB] decimal(12,0) NOT NULL,
    [EVK_ID_BIS] decimal(12,0) NULL,
    [PRGG_ANGELEGT] [sys].[datetime] NOT NULL,
    [PRGG_GEAENDERT] [sys].[datetime] NULL,
    [PRGG_FALLGRUPPE] decimal(1,0) NOT NULL,
    [PRGG_TYP] decimal(1,0) NOT NULL,
    [SVBA_NR] decimal(5,0) NULL,
    [WAEN_NR] decimal(5,0) NULL,
    [PRGG_UNTERBRECHBARKEIT] char(1) COLLATE Latin1_General_CI_AS NULL
);