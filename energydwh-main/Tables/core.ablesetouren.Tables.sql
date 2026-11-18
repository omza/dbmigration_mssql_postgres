CREATE TABLE [core].[ablesetouren]
(
    [id_mandant] [sys].[int] NOT NULL,
    [id_ablesetour] [sys].[int] NOT NULL,
    [ablesetour] varchar(100) COLLATE Latin1_General_CI_AS NULL,
    [sondertour] [sys].[int] NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__ablesetou__creat__5D2F300C] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__ablesetou__chang__5E235445] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_ablesetouren] PRIMARY KEY CLUSTERED ([id_mandant] ASC, [id_ablesetour] ASC)
);