CREATE TABLE [core].[geraete]
(
    [id_mandant] [sys].[int] NOT NULL,
    [id_geraet] varchar(32) COLLATE Latin1_General_CI_AS NOT NULL,
    [id_quellsystem] [sys].[int] NOT NULL,
    [quellsystem_ident] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [geraetenummer] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [id_geraeteart] [sys].[int] NOT NULL,
    [id_geraetetyp] [sys].[int] NULL,
    [id_standardgeraetetyp] [sys].[int] NOT NULL,
    [baujahr] [sys].[int] NULL,
    [eichung] [sys].[int] NULL,
    [naechste_eichung] [sys].[int] NULL,
    [los_nummer] varchar(60) COLLATE Latin1_General_CI_AS NULL,
    [id_losstatus] [sys].[int] NULL,
    [id_lagerstatus] [sys].[int] NULL,
    [zaehler_energierichtungen] varchar(40) COLLATE Latin1_General_CI_AS NULL,
    [zaehlerpin] varchar(4) COLLATE Latin1_General_CI_AS NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__geraete__created__1E27CDA0] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__geraete__changed__1F1BF1D9] DEFAULT (getdate()) NOT NULL,
    [gasdruck] [sys].[int] NULL,
    CONSTRAINT [pk_geraete] PRIMARY KEY CLUSTERED ([id_geraet] ASC)
);

ALTER TABLE [core].[geraete]
ADD CONSTRAINT [fk_geraete_energiearten]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);

ALTER TABLE [core].[geraete]
ADD CONSTRAINT [fk_geraete_geraetetypen]
FOREIGN KEY ([id_geraetetyp])
REFERENCES [core].[geraetetypen] ([id_geraetetyp]);

ALTER TABLE [core].[geraete]
ADD CONSTRAINT [fk_geraete_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);

ALTER TABLE [core].[geraete]
ADD CONSTRAINT [fk_geraete_standard_geraetetypen]
FOREIGN KEY ([id_standardgeraetetyp])
REFERENCES [core].[geraetetypen_standard] ([id_standardgeraetetyp]);

CREATE NONCLUSTERED INDEX [ix_geraete_mandant_energieart]
ON [core].[geraete] ([id_mandant] ASC, [id_energieart] ASC)
INCLUDE ([id_geraet], [geraetenummer], [id_geraetetyp], [id_standardgeraetetyp], [eichung], [naechste_eichung], [zaehlerpin]);