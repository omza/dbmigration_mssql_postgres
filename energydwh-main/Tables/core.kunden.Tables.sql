CREATE TABLE [core].[kunden]
(
    [id_kunde] decimal(12,0) NOT NULL,
    [id_mandant] [sys].[int] NULL,
    [kunden_nummer] varchar(20) COLLATE Latin1_General_CI_AS NOT NULL,
    [id_kundenstatus] [sys].[int] NOT NULL,
    [unbundling_art] varchar(18) COLLATE Latin1_General_CI_AS NOT NULL,
    [id_kundenkategorie] char(3) COLLATE Latin1_General_CI_AS NOT NULL,
    [id_kundengruppe] [sys].[int] NOT NULL,
    [id_turnusrechnung] [sys].[int] NOT NULL,
    [einzugsdatum] [sys].[datetime] NOT NULL,
    [auszugsdatum] [sys].[datetime] NULL,
    [id_rolle] decimal(19,0) NOT NULL,
    [rollenstatus] varchar(3) COLLATE Latin1_General_CI_AS NULL,
    [id_geschaeftspartner] decimal(19,0) NULL,
    [geschaeftspartner_nummer] varchar(22) COLLATE Latin1_General_CI_AS NOT NULL,
    [partnerstatus] varchar(3) COLLATE Latin1_General_CI_AS NULL,
    [geschaeftspartner_name] varchar(250) COLLATE Latin1_General_CI_AS NULL,
    [geschaeftspartner_name2] varchar(250) COLLATE Latin1_General_CI_AS NULL,
    [geschaeftspartner_zusatz] varchar(40) COLLATE Latin1_General_CI_AS NULL,
    [id_person] decimal(19,0) NULL,
    [titel] varchar(40) COLLATE Latin1_General_CI_AS NULL,
    [anrede] varchar(40) COLLATE Latin1_General_CI_AS NULL,
    [person_vorname] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [person_name] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [person_zusatz] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [geburtsdatum] [sys].[date] NULL,
    [geschlecht] varchar(3) COLLATE Latin1_General_CI_AS NULL,
    [person_typ] varchar(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [strasse] varchar(100) COLLATE Latin1_General_CI_AS NULL,
    [hausnummer] varchar(100) COLLATE Latin1_General_CI_AS NULL,
    [hausnummer_zusatz] varchar(4) COLLATE Latin1_General_CI_AS NULL,
    [laendercode] varchar(3) COLLATE Latin1_General_CI_AS NULL,
    [plz] varchar(10) COLLATE Latin1_General_CI_AS NULL,
    [ort] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [ortsteil] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [gemeindeschluessel] varchar(8) COLLATE Latin1_General_CI_AS NULL,
    [email] varchar(70) COLLATE Latin1_General_CI_AS NULL,
    [telefonnummer] varchar(30) COLLATE Latin1_General_CI_AS NULL,
    [mobilnummer] varchar(30) COLLATE Latin1_General_CI_AS NULL,
    [faxnummer] varchar(30) COLLATE Latin1_General_CI_AS NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__kunden__created___12804573] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__kunden__changed___137469AC] DEFAULT (getdate()) NOT NULL,
    [valid_from] [sys].[datetime] CONSTRAINT [DF__kunden__valid_fr__14688DE5] DEFAULT (CONVERT([datetime],'01.01.1900',(104))) NOT NULL,
    [valid_to] [sys].[datetime] CONSTRAINT [DF__kunden__valid_to__155CB21E] DEFAULT (CONVERT([datetime],'31.12.9999',(104))) NOT NULL,
    [active] [sys].[int] CONSTRAINT [DF__kunden__active__1650D657] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [pk_kunden] PRIMARY KEY CLUSTERED ([id_kunde] ASC, [valid_from] ASC)
);

ALTER TABLE [core].[kunden]
ADD CONSTRAINT [fk_kunde_kundengruppe]
FOREIGN KEY ([id_mandant], [id_kundengruppe])
REFERENCES [core].[kundengruppen] ([id_mandant], [id_kundengruppe]);

ALTER TABLE [core].[kunden]
ADD CONSTRAINT [fk_kunde_kundenkategorie]
FOREIGN KEY ([id_mandant], [id_kundenkategorie])
REFERENCES [core].[kundenkategorie] ([id_mandant], [id_kundenkategorie]);

ALTER TABLE [core].[kunden]
ADD CONSTRAINT [fk_kunde_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);