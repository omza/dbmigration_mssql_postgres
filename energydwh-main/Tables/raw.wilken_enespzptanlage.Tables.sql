CREATE TABLE [raw].[wilken_enespzptanlage]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [EZPA_ID] decimal(12,0) NOT NULL,
    [EANL_ID] decimal(12,0) NOT NULL,
    [ZPT_ID] decimal(12,0) NOT NULL,
    [EZPA_TYP] decimal(1,0) NOT NULL,
    [EZPA_BEGINN] [sys].[datetime] NOT NULL,
    [EZPA_ENDE] [sys].[datetime] NULL,
    [EZPA_VERLUSTFAKTOR] decimal(5,2) NULL,
    [EZPA_ANGELEGT] [sys].[datetime] NOT NULL,
    [EZPA_GEAENDERT] [sys].[datetime] NULL
);