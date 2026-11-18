CREATE TABLE [raw].[wilken_engeraetebeziehung]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [GBZ_ID] decimal(12,0) NOT NULL,
    [GBZD_ID] decimal(12,0) NOT NULL,
    [ZPG_ID_MASTER] decimal(12,0) NOT NULL,
    [ZPG_ID_SLAVE] decimal(12,0) NOT NULL,
    [GBZ_GUELTIGAB] [sys].[datetime] NOT NULL,
    [GBZ_GUELTIGBIS] [sys].[datetime] NULL,
    [GBZ_ANGELEGT] [sys].[datetime] NOT NULL,
    [GBZ_GEAENDERT] [sys].[datetime] NULL,
    [GBZ_STATUS] decimal(1,0) NOT NULL,
    [GBZ_ENDE_GEPLANT] [sys].[datetime] NULL,
    [GBZ_LMNCONNECTIONTYPE] decimal(3,0) NULL,
    [GBZ_ANGELEGTUSR_ID] decimal(5,0) NULL,
    [GBZ_ANGELEGTDBUSER] varchar(30) COLLATE Latin1_General_CI_AS NULL
);