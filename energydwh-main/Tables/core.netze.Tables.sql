CREATE TABLE [core].[netze]
(
    [id_netz] [sys].[int] NOT NULL,
    [id_mandant] [sys].[int] NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [netz_nummer] varchar(10) COLLATE Latin1_General_CI_AS NOT NULL,
    [netz] varchar(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [netz_status] [sys].[int] NOT NULL,
    [eigenes_netz] [sys].[int] NOT NULL,
    [grundversorger_netz] [sys].[int] NOT NULL,
    [kunden_netz] [sys].[int] NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__netze__created_a__47015CAF] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__netze__changed_a__47F580E8] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_netze] PRIMARY KEY CLUSTERED ([id_netz] ASC)
);

ALTER TABLE [core].[netze]
ADD CONSTRAINT [fk_netz_energiearten]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);

ALTER TABLE [core].[netze]
ADD CONSTRAINT [fk_netz_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);