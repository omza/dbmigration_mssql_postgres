CREATE TABLE [raw].[popstandorte]
(
    [Nr] [sys].[tinyint] NOT NULL,
    [Messlokation_Melo] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Bezeichnung] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Kurz_bezeichnung] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Kundenbeschaltung_aktuell_Februar_2024_PPPoE] [sys].[smallint] NULL,
    [Kundenbeschaltung_aktuell_Februar_2024_CMTS] [sys].[smallint] NULL,
    [Postleitzahl] [sys].[smallint] NULL,
    [Ort] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Region] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Straáe] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Hausnummer] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [LoRa_Messung] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Empfang] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Z_hler_NR] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Energietr_ger] nvarchar(50) COLLATE Latin1_General_CI_AS NULL
);