CREATE TABLE [core].[gruppe]
(
    [id_gruppe] [sys].[int] NOT NULL,
    [bezeichnung] varchar(MAX) NULL,
    CONSTRAINT [pk_gruppe] PRIMARY KEY CLUSTERED ([id_gruppe] ASC)
);
