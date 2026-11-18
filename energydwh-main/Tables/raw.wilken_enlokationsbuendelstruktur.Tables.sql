CREATE TABLE [raw].[wilken_enlokationsbuendelstruktur]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [LOKS_ID] decimal(12,0) NOT NULL,
    [LOKS_STRUKTURCODE] varchar(20) COLLATE Latin1_General_CI_AS NOT NULL,
    [LOKS_BEZEICHNUNG] varchar(200) COLLATE Latin1_General_CI_AS NOT NULL,
    [LOKS_GUELTIGAB] [sys].[datetime] NOT NULL,
    [LOKS_GUELTIGBIS] [sys].[datetime] NULL,
    [LOKS_ANGELEGT] [sys].[datetime] NOT NULL,
    [LOKS_GEAENDERT] [sys].[datetime] NULL,
    [LOKS_ANGELEGTUSR_ID] decimal(5,0) NULL,
    [LOKS_ANGELEGTDBUSER] varchar(30) COLLATE Latin1_General_CI_AS NULL
);