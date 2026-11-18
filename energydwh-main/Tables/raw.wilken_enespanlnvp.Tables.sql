CREATE TABLE [raw].[wilken_enespanlnvp]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [EANV_ID] decimal(12,0) NOT NULL,
    [ENVP_ID] decimal(12,0) NOT NULL,
    [EANL_ID] decimal(12,0) NOT NULL,
    [EANV_GUELTIGAB] [sys].[datetime] NOT NULL,
    [EANV_GUELTIGBIS] [sys].[datetime] NULL,
    [EANV_ANGELEGT] [sys].[datetime] NOT NULL,
    [EANV_GEAENDERT] [sys].[datetime] NULL,
    [EANV_VERTEILUNG] decimal(1,0) NULL
);