CREATE TABLE [core].[link_geraetebeziehungen]
(
    [id_link_geraet_geraet] [sys].[int] NOT NULL,
    [id_quellsystem] [sys].[int] NOT NULL,
    [id_beziehnungsart] [sys].[int] NOT NULL,
    [beziehungsart] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [gueltig_von] [sys].[date] NULL,
    [gueltig_bis] [sys].[date] NULL,
    [id_status_geraetebeziehung] [sys].[int] NULL,
    [master_id_geraet] varchar(32) COLLATE Latin1_General_CI_AS NULL,
    [master_quellsystem_ident] [sys].[int] NULL,
    [master_geraetenummer] varchar(70) COLLATE Latin1_General_CI_AS NULL,
    [master_id_mandant] [sys].[int] NOT NULL,
    [master_id_energieart] [sys].[int] NOT NULL,
    [master_einbaudatum] [sys].[date] NULL,
    [master_ausbaudatum] [sys].[date] NULL,
    [master_id_status] [sys].[int] NULL,
    [master_status] varchar(10) COLLATE Latin1_General_CI_AS NOT NULL,
    [slave_id_geraet] varchar(32) COLLATE Latin1_General_CI_AS NULL,
    [slave_quellsystem_ident] [sys].[int] NULL,
    [slave_geraetenummer] varchar(70) COLLATE Latin1_General_CI_AS NULL,
    [slave_id_mandant] [sys].[int] NOT NULL,
    [slave_id_energieart] [sys].[int] NOT NULL,
    [slave_einbaudatum] [sys].[date] NULL,
    [slave_ausbaudatum] [sys].[date] NULL,
    [slave_id_status] [sys].[int] NULL,
    [slave_status] varchar(10) COLLATE Latin1_General_CI_AS NOT NULL,
    CONSTRAINT [pk_link_geraetebeziehungen] PRIMARY KEY CLUSTERED ([id_link_geraet_geraet] ASC)
);

ALTER TABLE [core].[link_geraetebeziehungen]
ADD CONSTRAINT [fk_link_geraetebeziehungen_master_mandant]
FOREIGN KEY ([master_id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);

ALTER TABLE [core].[link_geraetebeziehungen]
ADD CONSTRAINT [fk_link_geraetebeziehungen_slave_mandant]
FOREIGN KEY ([slave_id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);