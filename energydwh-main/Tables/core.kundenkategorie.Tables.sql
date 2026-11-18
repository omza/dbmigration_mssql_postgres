CREATE TABLE [core].[kundenkategorie]
(
    [id_mandant] [sys].[int] NOT NULL,
    [id_kundenkategorie] char(3) COLLATE Latin1_General_CI_AS NOT NULL,
    [kundenkategorie] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__kundenkat__creat__76D82AFE] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__kundenkat__chang__77CC4F37] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_kundenkategorie] PRIMARY KEY CLUSTERED ([id_mandant] ASC, [id_kundenkategorie] ASC)
);

ALTER TABLE [core].[kundenkategorie]
ADD CONSTRAINT [fk_kundenkategorie_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);