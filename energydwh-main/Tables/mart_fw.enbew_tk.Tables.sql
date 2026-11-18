CREATE TABLE [mart_fw].[enbew_tk]
(
    [ZPT_ID] decimal(12,0) NOT NULL,
    [ZPT_METERINGCODE] varchar(33) COLLATE Latin1_General_CI_AS NOT NULL,
    [ABNAHMESTELLE] varchar(250) COLLATE Latin1_General_CI_AS NULL,
    [KND_NR1] varchar(20) COLLATE Latin1_General_CI_AS NULL,
    [KAT_NR] char(3) COLLATE Latin1_General_CI_AS NULL,
    [KAT_BEZEICHNUNG] varchar(40) COLLATE Latin1_General_CI_AS NULL,
    [PONAME] varchar(250) COLLATE Latin1_General_CI_AS NULL,
    [STRASSE] varchar(84) COLLATE Latin1_General_CI_AS NULL,
    [ORT] varchar(51) COLLATE Latin1_General_CI_AS NULL,
    [2020] [sys].[int] NULL,
    [2021] [sys].[int] NULL,
    [2022] [sys].[int] NULL,
    [2023] [sys].[int] NULL,
    [2024] [sys].[int] NULL,
    [KNG_BEZEICHNUNG] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [KND_LETZTERECHNUNG] [sys].[date] NULL,
    [KND_EINZUGDATUM] [sys].[date] NULL,
    [KND_AUSZUGDATUM] [sys].[date] NULL,
    [ABN_LTO_NR] decimal(5,0) NULL
);