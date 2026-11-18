CREATE TABLE [raw].[wilken_enlokstrukturobjekt]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [LOKSO_ID] decimal(12,0) NOT NULL,
    [LOKSO_OBJEKTCODE] varchar(20) COLLATE Latin1_General_CI_AS NOT NULL,
    [LOKSO_OBJEKTTYP] decimal(1,0) NOT NULL,
    [LOKSO_RICHTUNG] decimal(1,0) NULL,
    [LOKSO_EBENE] decimal(1,0) NOT NULL,
    [LOKSO_MELOFUNKTION] decimal(1,0) NULL,
    [LOKSO_ANGELEGT] [sys].[datetime] NOT NULL,
    [LOKSO_GEAENDERT] [sys].[datetime] NULL,
    [LOKSO_ANGELEGTUSR_ID] decimal(5,0) NULL,
    [LOKSO_ANGELEGTDBUSER] varchar(30) COLLATE Latin1_General_CI_AS NULL
);