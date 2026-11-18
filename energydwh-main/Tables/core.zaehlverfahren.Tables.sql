CREATE TABLE [core].[zaehlverfahren]
(
    [id_mandant] [sys].[int] NOT NULL,
    [id_zaehlverfahren] [sys].[int] NOT NULL,
    [id_energieart] [sys].[int] NULL,
    [edicode] varchar(3) COLLATE Latin1_General_CI_AS NULL,
    [zaehlverfahren] varchar(60) COLLATE Latin1_General_CI_AS NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__zaehlverf__creat__297A81DC] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__zaehlverf__chang__2A6EA615] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_zaehlverfahren] PRIMARY KEY CLUSTERED ([id_mandant] ASC, [id_zaehlverfahren] ASC)
);

ALTER TABLE [core].[zaehlverfahren]
ADD CONSTRAINT [fk_zaehlverfahren_energieart]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);

ALTER TABLE [core].[zaehlverfahren]
ADD CONSTRAINT [fk_zaehlverfahren_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);