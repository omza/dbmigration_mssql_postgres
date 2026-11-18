CREATE TABLE [dbo].[ivu_stage]
(
    [ZaehlerNummer] varchar(20) COLLATE Latin1_General_CI_AS NULL,
    [Messlokation] varchar(40) COLLATE Latin1_General_CI_AS NULL,
    [OBIS] varchar(10) COLLATE Latin1_General_CI_AS NULL,
    [Zeitstempel] [sys].[datetime] NULL,
    [Wert] [sys].[real] NULL
);