CREATE TABLE [dbo].[property]
(
    [id] [sys].[int] IDENTITY(1,1) NOT NULL,
    [name] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    CONSTRAINT [PK_property] PRIMARY KEY CLUSTERED ([id] ASC)
);