CREATE TABLE [core].[zaehlpunkt_typen]
(
    [id_zp_typ] [sys].[int] NOT NULL,
    [zaehlpunkttyp] varchar(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__zaehlpunk__creat__561FABFB] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__zaehlpunk__chang__5713D034] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_zaehlpunkt_typen] PRIMARY KEY CLUSTERED ([id_zp_typ] ASC)
);