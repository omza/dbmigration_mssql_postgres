CREATE TABLE [raw].[wilken_enmlk]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [MLK_ID] decimal(12,0) NOT NULL,
    [MLK_CODE] varchar(17) COLLATE Latin1_General_CI_AS NOT NULL,
    [MLK_ZUSATZ] varchar(400) COLLATE Latin1_General_CI_AS NULL,
    [MLK_ERSTMALIGE_KOMMUNIKATION] [sys].[datetime] NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [MLK_ANGELEGT] [sys].[datetime] NOT NULL,
    [MLK_GEAENDERT] [sys].[datetime] NULL,
    [MLK_UENB_UEBERMITTELT] [sys].[datetime] NULL,
    [MLK_EDM_INITIAL_NETZ] [sys].[datetime] NULL,
    [MLK_EDM_INITIAL_VERTRIEB] [sys].[datetime] NULL,
    [MLK_EDM_INIT_TRANSFER_NETZ] [sys].[datetime] NULL,
    [MLK_EDM_INIT_TRANSFER_VERTRIEB] [sys].[datetime] NULL,
    [MLK_VERARBEITUNGSNR_SDASYNCHRO] decimal(12,0) NULL,
    [MLK_MIG_ESM_BILANZIERUNG] [sys].[datetime] NULL,
    [MLK_BILANZIERUNG_RD] decimal(1,0) NULL
);