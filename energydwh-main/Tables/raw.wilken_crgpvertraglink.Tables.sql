CREATE TABLE [raw].[wilken_crgpvertraglink]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [GPVL_ID] decimal(12,0) NOT NULL,
    [GPVL_ANGELEGT] [sys].[datetime] NOT NULL,
    [GPVL_GEAENDERT] [sys].[datetime] NULL,
    [GPVL_FKTYP] decimal(3,0) NOT NULL,
    [GPVL_FKID] decimal(12,0) NOT NULL,
    [GPVG_ID] decimal(12,0) NOT NULL,
    [GPVL_GUELTIGAB] [sys].[datetime] NULL,
    [GPVL_GUELTIGBIS] [sys].[datetime] NULL,
    [GPVL_ANGELEGTUSR_ID] decimal(5,0) NULL,
    [GPVL_ANGELEGTDBUSER] varchar(30) COLLATE Latin1_General_CI_AS NULL
);