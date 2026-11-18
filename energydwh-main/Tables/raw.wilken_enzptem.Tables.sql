CREATE TABLE [raw].[wilken_enzptem]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [KEY] decimal(12,0) NOT NULL,
    [ZPTEM_ID] decimal(12,0) NOT NULL,
    [ZPT_ID] decimal(12,0) NOT NULL,
    [MES_ID] decimal(12,0) NULL,
    [ZPTEM_ZEITRAUMVON] [sys].[datetime] NOT NULL,
    [ZPTEM_ZEITRAUMBIS] [sys].[datetime] NOT NULL,
    [ZPTEM_VERBRAUCH] decimal(13,4) NULL,
    [ZPTEM_VERBRAUCHBER] decimal(13,4) NOT NULL,
    [ZPTEM_JAHRESVERBRAUCHBER] decimal(16,4) NULL,
    [ZPTEM_VERBRAUCHBERABZUG] decimal(13,4) NULL,
    [PRZ_ID] decimal(12,0) NULL,
    [LIF_ID] decimal(12,0) NULL,
    [ZPTEM_ART] decimal(1,0) NOT NULL,
    [ZPTEM_ANGELEGT] [sys].[datetime] NOT NULL,
    [ZPTEM_GEAENDERT] [sys].[datetime] NULL,
    [LSCH_ID] decimal(12,0) NULL,
    [MSC_ID] decimal(12,0) NULL,
    CONSTRAINT [pk_wilken_zptem] PRIMARY KEY CLUSTERED ([KEY] ASC)
);