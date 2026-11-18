CREATE TABLE [raw].[wilken_enlastprofil]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [LPR_NR] decimal(5,0) NULL,
    [ENE_ID] decimal(2,0) NOT NULL,
    [LPR_BEZEICHNUNG] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [LPR_EDICODE] varchar(3) COLLATE Latin1_General_CI_AS NULL,
    [LPR_ANGELEGT] [sys].[datetime] NOT NULL,
    [LPR_GEAENDERT] [sys].[datetime] NULL,
    [NBT_ID] decimal(12,0) NULL,
    [WIC_NR] varchar(5) COLLATE Latin1_General_CI_AS NULL,
    [LPR_ART_WICHTUNG] decimal(1,0) NULL,
    [LPR_AKTIV] decimal(1,0) NULL,
    [LPR_VORGABE] decimal(1,0) NULL,
    [LPR_ID] decimal(12,0) NOT NULL,
    [LPR_REFERENZLASTGANG] decimal(1,0) NULL,
    [TMS_ID_VORGABE] decimal(12,0) NULL,
    [PRS_NR_VORGABE] decimal(5,0) NULL,
    [LPR_BILVERFAHREN] varchar(3) COLLATE Latin1_General_CI_AS NULL,
    [LPR_ID_SYNTHETISCH] decimal(12,0) NULL
);