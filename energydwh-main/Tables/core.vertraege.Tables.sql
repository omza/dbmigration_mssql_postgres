CREATE TABLE [core].[vertraege]
(
    [id_vertrag] [sys].[int] NOT NULL,
    [id_mandant] [sys].[int] NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [vertragsnummer] varchar(40) COLLATE Latin1_General_CI_AS NULL,
    [id_vertragsart] [sys].[int] NOT NULL,
    [vertragsbeginn] [sys].[date] NOT NULL,
    [vertragsende] [sys].[date] NOT NULL,
    [vertragsbindung_bis] [sys].[date] NULL,
    [id_vertragsstatus] [sys].[int] NOT NULL,
    [vertrag_gekuendigt_zum] [sys].[date] NULL,
    [id_produkt] [sys].[int] NOT NULL,
    [id_produktvariante] [sys].[int] NOT NULL,
    [grundversorgung] [sys].[int] NULL,
    [kuendigungsfrist_ablauf] [sys].[date] NULL,
    [belieferung_ab] [sys].[date] NULL,
    [belieferung_bis] [sys].[date] NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__vertraege__creat__61B552EB] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__vertraege__chang__62A97724] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_vertraege] PRIMARY KEY CLUSTERED ([id_vertrag] ASC)
);

ALTER TABLE [core].[vertraege]
ADD CONSTRAINT [fk_vertrag_energieart]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);

ALTER TABLE [core].[vertraege]
ADD CONSTRAINT [fk_vertrag_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);

ALTER TABLE [core].[vertraege]
ADD CONSTRAINT [fk_vertrag_produkt]
FOREIGN KEY ([id_produkt], [id_produktvariante])
REFERENCES [core].[produkte] ([id_produkt], [id_produktvariante]);