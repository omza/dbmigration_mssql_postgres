CREATE TABLE [core].[lastprofile]
(
    [id_lastprofil] [sys].[int] NOT NULL,
    [id_mandant] [sys].[int] NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [lastprofil_nummer] [sys].[int] NULL,
    [edicode] varchar(10) COLLATE Latin1_General_CI_AS NULL,
    [lastprofil] varchar(255) COLLATE Latin1_General_CI_AS NULL,
    [lastprofil_aktiv] [sys].[int] NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__lastprofi__creat__20E53BDB] DEFAULT (getdate()) NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__lastprofi__chang__21D96014] DEFAULT (getdate()) NULL,
    CONSTRAINT [pk_lastprofile] PRIMARY KEY CLUSTERED ([id_lastprofil] ASC)
);

ALTER TABLE [core].[lastprofile]
ADD CONSTRAINT [fk_lastprofil_energieart]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);

ALTER TABLE [core].[lastprofile]
ADD CONSTRAINT [fk_lastprofil_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);