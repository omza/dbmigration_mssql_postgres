CREATE TABLE [core].[kalender]
(
    [zeitstempel_utc] [sys].[datetime] NOT NULL,
    [zeitstempel] [sys].[datetime] NOT NULL,
    [tag_utc] [sys].[date] NOT NULL,
    [tag] [sys].[date] NOT NULL,
    [isodate_utc] [sys].[bigint] NOT NULL,
    [isodate] [sys].[bigint] NOT NULL,
    [id_typtag] [sys].[int] NOT NULL,
    [stunde_utc] [sys].[int] NULL,
    [stunde] [sys].[int] NULL,
    [bstunde] varchar(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [minute] [sys].[int] NOT NULL,
    [id_zeitumstellung] [sys].[int] NOT NULL,
    [id_wochentag] [sys].[int] NOT NULL,
    [kalenderwoche] [sys].[int] NOT NULL,
    [quartal] [sys].[int] NOT NULL,
    [offset_minutes] [sys].[int] CONSTRAINT [DF__kalender__offset__4E746892] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [pk_kalender] PRIMARY KEY CLUSTERED ([zeitstempel_utc] ASC)
);