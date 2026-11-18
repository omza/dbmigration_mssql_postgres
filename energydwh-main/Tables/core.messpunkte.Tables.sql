CREATE TABLE [core].[messpunkte]
(
    [id_messpunkt] [sys].[int] IDENTITY(1,1) NOT NULL,
    [id_mandant] [sys].[int] NULL,
    [id_energieart] [sys].[int] NULL,
    [id_geraeteart] [sys].[int] NULL,
    [id_geraetetyp] [sys].[int] NULL,
    [id_quellsystem] [sys].[int] NOT NULL,
    [messpunkt_ident] nvarchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [messpunkt_name] nvarchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [messpunkt_beschreibung] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [location_beschreibung] nvarchar(100) COLLATE Latin1_General_CI_AS NULL,
    [location_lat] decimal(10,8) NULL,
    [location_lon] decimal(10,8) NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__messpunkt__creat__07D70320] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__messpunkt__chang__08CB2759] DEFAULT (getdate()) NULL,
    [messpunkt_serialnummer] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    CONSTRAINT [pk_messpunkte] PRIMARY KEY CLUSTERED ([id_messpunkt] ASC),
    CONSTRAINT [unique_messpunkte] UNIQUE CLUSTERED ([id_quellsystem] ASC, [messpunkt_ident] ASC)
);

ALTER TABLE [core].[messpunkte]
ADD CONSTRAINT [fk_messpunkte_energiearten]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);

ALTER TABLE [core].[messpunkte]
ADD CONSTRAINT [fk_messpunkte_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);