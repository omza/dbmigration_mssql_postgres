CREATE TABLE [raw].[EnergieverbraucherWilhelmTel]
(
    [Kunden_Nr] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Name] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Abnahmestelle] nvarchar(MAX) COLLATE Latin1_General_CI_AS NULL,
    [PLZ] [sys].[int] NULL,
    [Ort] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Abgleich_mit_Rainer_Hoffs_Liste_ob_vorhanden_NV_bei_ihm_nicht_geführt] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [abgerechneter_Verbrauch_in_kWh_aus_2020] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [abgerechneter_Verbrauch_in_kWh_aus_2021] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [abgerechneter_Verbrauch_in_kWh_aus_2022] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [abgerechneter_Verbrauch_in_kWh_aus_2023] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [abgerechneter_Verbrauch_in_kWh_aus_2024] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [abgegrenzter_Jahresverbrauch_in_kWh_aus_2025] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Herkunft_Jessica_EXCEL] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Ort2] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Netzebene] [sys].[int] NULL,
    [Messlokation] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [column17] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [column18] nvarchar(50) COLLATE Latin1_General_CI_AS NULL
);