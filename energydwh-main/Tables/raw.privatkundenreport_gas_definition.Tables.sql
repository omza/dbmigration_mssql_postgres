CREATE TABLE [raw].[privatkundenreport_gas_definition]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [Produktnummer] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Überschrift1] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Überschrift2] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Zusammenfassung] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Prognosewert] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Staffel_Von] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Staffel_Bis] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Sort] varchar(4000) COLLATE Latin1_General_CI_AS NULL
);