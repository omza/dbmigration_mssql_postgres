CREATE TABLE [dbo].[sysdiagrams]
(
    [name] [sys].[sysname] NOT NULL,
    [principal_id] [sys].[int] NOT NULL,
    [diagram_id] [sys].[int] IDENTITY(1,1) NOT NULL,
    [version] [sys].[int] NULL,
    [definition] varbinary(MAX) NULL,
    CONSTRAINT [PK__sysdiagr__C2B05B615A9376F2] PRIMARY KEY CLUSTERED ([diagram_id] ASC),
    CONSTRAINT [UK_principal_name] UNIQUE CLUSTERED ([principal_id] ASC, [name] ASC)
);