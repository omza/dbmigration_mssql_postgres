CREATE TABLE [core].[messstellenbetreiber]
(
    [id_messstellenbetreiber] [sys].[int] NOT NULL,
    [id_mandant] [sys].[int] NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [messstellenbetreiber] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [eigener_messstellenbetreiber] [sys].[int] NOT NULL,
    [aktiver_messstellenbetreiber] [sys].[int] NOT NULL,
    [id_kunde] [sys].[int] NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__messstell__creat__493EDCA6] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__messstell__chang__4A3300DF] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_messstellenbetreiber] PRIMARY KEY CLUSTERED ([id_messstellenbetreiber] ASC)
);

ALTER TABLE [core].[messstellenbetreiber]
ADD CONSTRAINT [fk_mbt_energiearten]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);

ALTER TABLE [core].[messstellenbetreiber]
ADD CONSTRAINT [fk_mbt_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);