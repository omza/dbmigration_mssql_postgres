CREATE TABLE [core].[obis]
(
    [id_obis] [sys].[int] NOT NULL,
    [obis_kennziffer] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [obis_einheit] varchar(20) COLLATE Latin1_General_CI_AS NOT NULL,
    [obis_beschreibung] varchar(200) COLLATE Latin1_General_CI_AS NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [obis_energierichtung] [sys].[int] NOT NULL,
    [obis_medium] [sys].[int] NOT NULL,
    [obis_kanal] [sys].[int] NOT NULL,
    [obis_messgroesse] [sys].[int] NOT NULL,
    [obis_messart] [sys].[int] NOT NULL,
    [obis_tarifstufe] [sys].[int] NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__obis__created_at__135DC465] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__obis__changed_at__1451E89E] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_obis] PRIMARY KEY CLUSTERED ([id_obis] ASC),
    CONSTRAINT [UC_obis_kennziffer] UNIQUE CLUSTERED ([obis_kennziffer] ASC)
);

ALTER TABLE [core].[obis]
ADD CONSTRAINT [FK_obis_energiearten]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);