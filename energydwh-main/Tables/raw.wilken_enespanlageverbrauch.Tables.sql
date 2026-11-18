CREATE TABLE [raw].[wilken_enespanlageverbrauch]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [EANLV_ID] decimal(12,0) NOT NULL,
    [KND_ID] decimal(12,0) NOT NULL,
    [PRZ_ID] decimal(12,0) NOT NULL,
    [EANL_ID] decimal(12,0) NOT NULL,
    [EANLV_VERBRAUCH_BER_ESP] decimal(13,4) NOT NULL,
    [EANLV_ANTEIL_ESP_PROZ] decimal(5,2) NOT NULL,
    [EANLV_VERBRAUCH_BER_ERZ] decimal(13,4) NOT NULL,
    [EANLV_ANTEIL_EIGEN_PROZ] decimal(5,2) NOT NULL,
    [EANLV_ANGELEGT] [sys].[datetime] NOT NULL,
    [EANLV_GEAENDERT] [sys].[datetime] NULL,
    [ZPT_ID_EINSP] decimal(12,0) NOT NULL,
    [EANLV_VERBRAUCH_BER_EIGEN] decimal(13,4) NOT NULL,
    [EANLV_VERBRAUCH_ERZ_GEM] decimal(13,4) NOT NULL
);