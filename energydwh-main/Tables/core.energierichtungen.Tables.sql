CREATE TABLE [core].[energierichtungen]
(
    [id_energierichtung] [sys].[int] NOT NULL,
    [energierichtung] varchar(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [wilken_zmlk_typ] [sys].[int] NULL,
    [wilken_obs_energierichtung] [sys].[int] NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__energieri__creat__665613C4] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__energieri__chang__674A37FD] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_energierichtungen] PRIMARY KEY CLUSTERED ([id_energierichtung] ASC)
);