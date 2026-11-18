CREATE TABLE [raw].[wilken_enespanlstromerzeugungseinheit]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [EASEE_ID] decimal(12,0) NOT NULL,
    [EANL_ID] decimal(12,0) NOT NULL,
    [EASEE_MASTRNR] varchar(20) COLLATE Latin1_General_CI_AS NOT NULL,
    [EASEE_REGISTRIERUNGS_DATUM] [sys].[datetime] NULL,
    [EASEE_ZUGEORDNET_VON] [sys].[datetime] NOT NULL,
    [EASEE_ZUGEORDNET_BIS] [sys].[datetime] NULL,
    [EASEE_ANGELEGT] [sys].[datetime] NOT NULL,
    [EASEE_GEAENDERT] [sys].[datetime] NULL,
    [EASEE_TR_ID] varchar(20) COLLATE Latin1_General_CI_AS NULL,
    [EASEE_SEE_SONSTIGE_ANLAGE] decimal(1,0) NULL,
    [TRE_ID] decimal(12,0) NULL
);