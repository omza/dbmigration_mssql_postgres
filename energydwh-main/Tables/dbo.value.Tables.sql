CREATE TABLE [dbo].[value]
(
    [id] [sys].[bigint] IDENTITY(1,1) NOT NULL,
    [property_id] [sys].[int] NULL,
    [entity_id] [sys].[bigint] NULL,
    [value] nvarchar(75) COLLATE Latin1_General_CI_AS NULL,
    [valid_since] [sys].[datetime] NULL,
    CONSTRAINT [PK_value] PRIMARY KEY CLUSTERED ([id] ASC)
);