CREATE TABLE [stage].[ImportPrivatkundenreportStromV2]
(
    [ultimo] [sys].[date] NULL,
    [energieart] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [ueberschrift1] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [ueberschrift2] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [sortierung] [sys].[tinyint] NULL,
    [anzahl_abnahmestellen] [sys].[smallint] NULL,
    [menge_abnahmestellen_kwh] [sys].[int] NULL
);