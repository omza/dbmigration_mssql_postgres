CREATE TABLE [dbo].[log_data]
(
    [id] [sys].[int] IDENTITY(1,1) NOT NULL,
    [log_id] [sys].[int] NULL,
    [log_row] nvarchar(512) COLLATE Latin1_General_CI_AS NULL,
    CONSTRAINT [PK_log_data] PRIMARY KEY CLUSTERED ([id] ASC)
);