CREATE TABLE [core].[messpunkt_attribute]
(
    [id_messpunkt] [sys].[int] NOT NULL,
    [id_messpunkt_attribut] [sys].[int] NOT NULL,
    [wert] nvarchar(200) COLLATE Latin1_General_CI_AS NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__messpunkt__creat__4D8BFCA8] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__messpunkt__chang__4E8020E1] DEFAULT (getdate()) NULL,
    CONSTRAINT [pk_messpunkt_attribut] PRIMARY KEY CLUSTERED ([id_messpunkt] ASC, [id_messpunkt_attribut] ASC)
);

ALTER TABLE [core].[messpunkt_attribute]
ADD CONSTRAINT [fk_messpunkt_messpunkt_attribut]
FOREIGN KEY ([id_messpunkt])
REFERENCES [core].[messpunkte] ([id_messpunkt]);