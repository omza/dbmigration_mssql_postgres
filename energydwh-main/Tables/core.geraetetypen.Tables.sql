CREATE TABLE [core].[geraetetypen]
(
    [id_geraetetyp] [sys].[int] IDENTITY(1,1) NOT NULL,
    [id_mandant] [sys].[int] NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [id_quellsystem] [sys].[int] NOT NULL,
    [geraetetyp] nvarchar(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [quellsystem_ident] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [quellsystem_status] decimal(1,0) NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__geraetety__creat__66CB1510] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__geraetety__chang__67BF3949] DEFAULT (getdate()) NOT NULL,
    [nenngroesse] varchar(40) COLLATE Latin1_General_CI_AS NULL,
    CONSTRAINT [pk_geraetetypen] PRIMARY KEY CLUSTERED ([id_geraetetyp] ASC)
);

ALTER TABLE [core].[geraetetypen]
ADD CONSTRAINT [fk_ztp_energieart]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);

ALTER TABLE [core].[geraetetypen]
ADD CONSTRAINT [fk_ztp_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);