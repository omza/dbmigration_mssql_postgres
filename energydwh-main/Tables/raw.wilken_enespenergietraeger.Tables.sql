CREATE TABLE [raw].[wilken_enespenergietraeger]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [EETR_NR] decimal(5,0) NOT NULL,
    [EETR_BEZEICHNUNG] varchar(40) COLLATE Latin1_General_CI_AS NOT NULL,
    [EETR_KUERZEL] varchar(2) COLLATE Latin1_General_CI_AS NOT NULL,
    [EETR_GUELTIGAB] [sys].[datetime] NOT NULL,
    [EETR_GUELTIGBIS] [sys].[datetime] NULL,
    [EETR_EDMCODE_LIF] varchar(35) COLLATE Latin1_General_CI_AS NULL,
    [EETR_EDMCODE_ZRT] varchar(35) COLLATE Latin1_General_CI_AS NULL,
    [EETR_ANGELEGT] [sys].[datetime] NOT NULL,
    [EETR_GEAENDERT] [sys].[datetime] NULL,
    [EETR_EINSPEISEART] decimal(1,0) NOT NULL,
    [EETR_GRENZE_VOLLLASTSTUNDEN] decimal(5,0) NULL
);