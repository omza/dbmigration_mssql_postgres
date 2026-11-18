CREATE TABLE [core].[energiearten]
(
    [id_energieart] [sys].[int] NOT NULL,
    [energieart] varchar(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__energiear__creat__0CB0C6D6] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__energiear__chang__0DA4EB0F] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_energiearten] PRIMARY KEY CLUSTERED ([id_energieart] ASC)
);