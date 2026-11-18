CREATE TABLE [raw].[wilken_enzmk]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [KEY] decimal(12,0) NOT NULL,
    [ZPT_ID] decimal(12,0) NOT NULL,
    [ZMK_DURCHSCHNITTSVERBRAUCH] decimal(13,2) NOT NULL,
    [ZMK_VERBRZEITRAUMVON] [sys].[datetime] NOT NULL,
    [ZMK_VERBRZEITRAUMBIS] [sys].[datetime] NOT NULL,
    [ZMK_GRUPPE] decimal(2,0) NOT NULL,
    [ZMK_ERMITTELT_AM] [sys].[datetime] NOT NULL,
    [ZMK_BERECHNET] decimal(1,0) NOT NULL,
    [ZMK_LIEFERRICHTUNG] decimal(1,0) NOT NULL,
    [ZMK_ANGELEGT] [sys].[datetime] NOT NULL,
    [ZMK_GEAENDERT] [sys].[datetime] NULL,
    CONSTRAINT [pk_wilken_enzmk] PRIMARY KEY CLUSTERED ([KEY] ASC)
);