CREATE TABLE [core].[spannungsebenen]
(
    [id_spannungsebene] [sys].[int] NOT NULL,
    [id_mandant] [sys].[int] NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [spannungsebene] varchar(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [edicode] varchar(10) COLLATE Latin1_General_CI_AS NULL,
    [created_at] [sys].[datetime] NULL,
    [changed_at] [sys].[datetime] NULL,
    CONSTRAINT [pk_spannungsebenen] PRIMARY KEY CLUSTERED ([id_spannungsebene] ASC, [id_mandant] ASC)
);