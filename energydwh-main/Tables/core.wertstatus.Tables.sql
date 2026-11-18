CREATE TABLE [core].[wertstatus]
(
    [id_wertstatus] [sys].[int] NOT NULL,
    [wertstatus] varchar(60) COLLATE Latin1_General_CI_AS NOT NULL,
    [argos_wertstatus] [sys].[int] NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__wertstatu__creat__10C14EDC] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__wertstatu__chang__11B57315] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [pk_wertstatus] PRIMARY KEY CLUSTERED ([id_wertstatus] ASC)
);