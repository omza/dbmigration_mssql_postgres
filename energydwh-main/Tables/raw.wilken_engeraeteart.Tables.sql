CREATE TABLE [raw].[wilken_engeraeteart]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [GER_ID] decimal(12,0) NOT NULL,
    [GER_BEZEICHNUNG] varchar(40) COLLATE Latin1_General_CI_AS NOT NULL,
    [GER_GERAETEGRUNDTYP] decimal(2,0) NOT NULL,
    [GER_STANDARD] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [GER_AUTO_NR] decimal(12,0) NULL,
    [GER_AUTO_NR_PRAEFIX] varchar(10) COLLATE Latin1_General_CI_AS NULL,
    [GER_AUTO_NR_LAENGE] decimal(2,0) NULL,
    [GER_ANGELEGT] [sys].[datetime] NOT NULL,
    [GER_GEAENDERT] [sys].[datetime] NULL
);