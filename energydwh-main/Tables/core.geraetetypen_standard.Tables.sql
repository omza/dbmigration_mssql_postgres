CREATE TABLE [core].[geraetetypen_standard]
(
    [id_standardgeraetetyp] [sys].[int] IDENTITY(1,1) NOT NULL,
    [id_mandant] [sys].[int] NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [standardgeraetetyp] varchar(60) COLLATE Latin1_General_CI_AS NOT NULL,
    [wilken_sztp_nr] decimal(5,0) NULL,
    [wilken_sztp_aktiv] decimal(1,0) NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__geraetety__creat__5A653E2B] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__geraetety__chang__5B596264] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_geraetetypen_standard] PRIMARY KEY CLUSTERED ([id_standardgeraetetyp] ASC),
    CONSTRAINT [unique_geraetetypen_standard] UNIQUE CLUSTERED ([id_mandant] ASC, [wilken_sztp_nr] ASC)
);

ALTER TABLE [core].[geraetetypen_standard]
ADD CONSTRAINT [fk_geraetetypen_standard_energieart]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);

ALTER TABLE [core].[geraetetypen_standard]
ADD CONSTRAINT [fk_geraetetypen_standard_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);