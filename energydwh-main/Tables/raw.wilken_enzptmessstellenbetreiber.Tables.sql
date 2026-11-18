CREATE TABLE [raw].[wilken_enzptmessstellenbetreiber]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [ZMB_ID] decimal(12,0) NOT NULL,
    [ZPT_ID] decimal(12,0) NOT NULL,
    [ZMB_GUELTIGAB] [sys].[datetime] NOT NULL,
    [ZMB_GUELTIGBIS] [sys].[datetime] NULL,
    [ZMB_STATUS] decimal(1,0) NOT NULL,
    [MBT_ID] decimal(12,0) NOT NULL,
    [ZMB_GRUNDZUSTAENDIG] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [ZMB_KZ_WEITERVERPFLICHTUNG] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [ORD_ID] decimal(12,0) NULL,
    [ZMB_ANGELEGT] [sys].[datetime] NOT NULL,
    [ZMB_GEAENDERT] [sys].[datetime] NULL,
    [ZMB_ANGELEGTUSR_ID] decimal(5,0) NULL,
    [ZMB_ANGELEGTDBUSER] varchar(30) COLLATE Latin1_General_CI_AS NULL,
    [MBT_ID_MALO_ABW] decimal(12,0) NULL,
    [ZMB_RUECKKEHR_ZUM_GMSB] decimal(1,0) NOT NULL,
    [ZMB_ZUORDNUNGSART] decimal(1,0) NULL
);