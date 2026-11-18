CREATE TABLE [core].[objekt_hierarchien]
(
    [id_netz] [sys].[int] IDENTITY(1,1) NOT NULL,
    [id_mandant] [sys].[int] NOT NULL,
    [netz] varchar(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [netz_beschreibung] varchar(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__netze__created_a__6860B9CC] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__netze__changed_a__6954DE05] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_netz] PRIMARY KEY CLUSTERED ([id_netz] ASC)
);

ALTER TABLE [core].[objekt_hierarchien]
ADD CONSTRAINT [fk_netze_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);