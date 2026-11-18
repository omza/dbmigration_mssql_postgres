CREATE TABLE [core].[netz_knoten_attribute]
(
    [id_knoten] [sys].[int] NOT NULL,
    [id_knoten_attribut] [sys].[int] NOT NULL,
    [wert] nvarchar(200) COLLATE Latin1_General_CI_AS NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__netz_knot__creat__7A7F6A07] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__netz_knot__chang__7B738E40] DEFAULT (getdate()) NULL,
    CONSTRAINT [pk_netz_knoten_attribut] PRIMARY KEY CLUSTERED ([id_knoten] ASC, [id_knoten_attribut] ASC)
);

ALTER TABLE [core].[netz_knoten_attribute]
ADD CONSTRAINT [fk_attribute_netz_knoten]
FOREIGN KEY ([id_knoten])
REFERENCES [core].[netz_knoten] ([id_knoten]);