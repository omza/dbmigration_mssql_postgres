CREATE TABLE [core].[netz_knoten]
(
    [id_knoten] [sys].[int] IDENTITY(1,1) NOT NULL,
    [id_netz] [sys].[int] NOT NULL,
    [knoten_name] varchar(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [knoten_beschreibung] varchar(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [knoten_ident] nvarchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [id_quellsystem] [sys].[int] NOT NULL,
    [knoten_straße] varchar(70) COLLATE Latin1_General_CI_AS NULL,
    [knoten_hausnummer] [sys].[int] NULL,
    [knoten_hausnummer_zusatz] varchar(30) COLLATE Latin1_General_CI_AS NULL,
    [knoten_plz] varchar(10) COLLATE Latin1_General_CI_AS NULL,
    [knoten_ort] varchar(40) COLLATE Latin1_General_CI_AS NULL,
    [knoten_lat] decimal(11,8) NULL,
    [knoten_lon] decimal(11,8) NULL,
    [knoten_location_type] varchar(20) COLLATE Latin1_General_CI_AS NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__netz_knot__creat__6D256EE9] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__netz_knot__chang__6E199322] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_netz_knoten] PRIMARY KEY CLUSTERED ([id_knoten] ASC)
);

ALTER TABLE [core].[netz_knoten]
ADD CONSTRAINT [fk_knoten_netz]
FOREIGN KEY ([id_netz])
REFERENCES [core].[objekt_hierarchien] ([id_netz]);