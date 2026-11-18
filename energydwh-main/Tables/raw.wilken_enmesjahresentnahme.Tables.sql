CREATE TABLE [raw].[wilken_enmesjahresentnahme]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [MES_ID] decimal(12,0) NOT NULL,
    [MJE_ID] decimal(12,0) NOT NULL,
    [MJE_RECPRZ_ID] decimal(12,0) NOT NULL,
    [MJE_GUELTIGAB] [sys].[datetime] NOT NULL,
    [MJE_JAHRESENTNAHME] decimal(12,2) NULL,
    [MJE_STICHTAG] [sys].[datetime] NULL,
    [MJE_STAMMDATENAENDERUNG] decimal(1,0) NOT NULL,
    [MJE_JAHRESENTNAHME_NT] decimal(12,2) NULL,
    [PRZ_ID] decimal(12,0) NOT NULL,
    [MJE_KUNDENWERT] decimal(15,5) NULL,
    [MJE_SPEZIF_ARBEIT] decimal(15,3) NULL,
    [MJE_ARBEIT_TLP] decimal(15,3) NULL,
    [MJE_ABSCHLAG] decimal(12,2) NULL,
    [SDA_ID] decimal(12,0) NULL,
    [SDAK_ID] decimal(12,0) NULL
);