CREATE TABLE [raw].[gasreglerdruckpruefung_md]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [Straße] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Nr_] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [DN] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [HE_Baujahr] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Bemerkung] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [GDR_Typ] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [GDR_Typenschlüssel] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Hersteller] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [GDR_Ausgangsdruck] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Werks/Eichung?] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [GDR_Bj_] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Reglerprüfung] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [nächste_Prüfung] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Hausanschlusskontrolle] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [RLM_Messung?] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Zählergröße] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Zählerwechsel] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Bearbeiter] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [Bilder] varchar(4000) COLLATE Latin1_General_CI_AS NULL
);