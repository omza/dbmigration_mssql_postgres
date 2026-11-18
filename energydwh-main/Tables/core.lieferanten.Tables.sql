CREATE TABLE [core].[lieferanten]
(
    [id_lieferant] [sys].[int] NOT NULL,
    [id_mandant] [sys].[int] NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [lieferant] varchar(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [lieferant_kurz] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [eic_nummer] varchar(20) COLLATE Latin1_General_CI_AS NULL,
    [id_kunde] decimal(12,0) NULL,
    [flag_aktiv] [sys].[int] NOT NULL,
    [created_at] [sys].[date] CONSTRAINT [DF__lieferant__creat__4F3E6F99] DEFAULT (getdate()) NULL,
    [changed_at] [sys].[date] CONSTRAINT [DF__lieferant__chang__503293D2] DEFAULT (getdate()) NULL,
    CONSTRAINT [pk_lieferanten] PRIMARY KEY CLUSTERED ([id_lieferant] ASC)
);

ALTER TABLE [core].[lieferanten]
ADD CONSTRAINT [fk_lieferant_energieart]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);

ALTER TABLE [core].[lieferanten]
ADD CONSTRAINT [fk_lieferant_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);