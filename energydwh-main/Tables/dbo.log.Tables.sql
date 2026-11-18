CREATE TABLE [dbo].[log]
(
    [id] [sys].[int] IDENTITY(1,1) NOT NULL,
    [timestamp] [sys].[datetime] NULL,
    [message] nvarchar(75) COLLATE Latin1_General_CI_AS NULL,
    CONSTRAINT [PK_log] PRIMARY KEY CLUSTERED ([id] ASC)
);