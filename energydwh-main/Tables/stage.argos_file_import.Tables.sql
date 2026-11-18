CREATE TABLE [stage].[argos_file_import]
(
    [argos_file_id] [sys].[bigint] IDENTITY(1,1) NOT NULL,
    [load_log_id] [sys].[bigint] NOT NULL,
    [filename] varchar(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [Kunden_Name] varchar(100) COLLATE Latin1_General_CI_AS NULL,
    [Kunden_Nummer] varchar(100) COLLATE Latin1_General_CI_AS NULL,
    [Meteringcode] varchar(33) COLLATE Latin1_General_CI_AS NULL,
    [Zaehlernummer] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Kanal] [sys].[int] NULL,
    [OBIS] varchar(100) COLLATE Latin1_General_CI_AS NULL,
    [Zeitraum] [sys].[date] NULL,
    [Wandlerfaktor] [sys].[int] NULL,
    [Raster_Minuten] [sys].[int] NULL,
    [Messeinheit] varchar(5) COLLATE Latin1_General_CI_AS NULL,
    [Anzahl_Werte] [sys].[int] NULL,
    [kWh] decimal(18,3) NULL,
    CONSTRAINT [PK_argos_file_import] PRIMARY KEY CLUSTERED ([argos_file_id] ASC),
    CONSTRAINT [UC_argos_file_import_loadlogid_filename] UNIQUE CLUSTERED ([load_log_id] ASC, [filename] ASC)
);