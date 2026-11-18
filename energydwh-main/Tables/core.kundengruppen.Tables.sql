CREATE TABLE [core].[kundengruppen]
(
    [id_mandant] [sys].[int] NOT NULL,
    [id_kundengruppe] [sys].[int] NOT NULL,
    [kundengruppe] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [created_at] [sys].[datetime] NOT NULL,
    [changed_at] [sys].[datetime] NOT NULL,
    CONSTRAINT [pk_kundengruppen] PRIMARY KEY CLUSTERED ([id_mandant] ASC, [id_kundengruppe] ASC)
);

ALTER TABLE [core].[kundengruppen]
ADD CONSTRAINT [fk_kundengruppe_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);