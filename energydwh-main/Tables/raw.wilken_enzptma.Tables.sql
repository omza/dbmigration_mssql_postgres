CREATE TABLE [raw].[wilken_enzptma]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [KEY] decimal(12,0) NOT NULL,
    [ZPTMA_ID] decimal(12,0) NOT NULL,
    [ZPTEM_ID] decimal(12,0) NOT NULL,
    [ZPTMA_OBISCODE] varchar(35) COLLATE Latin1_General_CI_AS NULL,
    [MND_ID] decimal(5,0) NULL,
    [VBA_NR] decimal(5,0) NULL,
    [ZPTMA_VERBRAUCH] decimal(13,4) NULL,
    [ZPTMA_VERBRAUCHBER] decimal(13,4) NOT NULL,
    [ZPTMA_JAHRESVERBRAUCHBER] decimal(15,4) NULL,
    [ZPTMA_VERBRAUCHBERABZUG] decimal(13,4) NULL,
    [ZPTMA_ANGELEGT] [sys].[datetime] NOT NULL,
    [ZPTMA_GEAENDERT] [sys].[datetime] NULL,
    [ZPTMA_KONTROLLMENGE] char(1) COLLATE Latin1_General_CI_AS NULL,
    CONSTRAINT [pk_wilken_enzptma] PRIMARY KEY CLUSTERED ([KEY] ASC)
);