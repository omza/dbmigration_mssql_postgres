CREATE TABLE [dbo].[zaehlpunkte]
(
    [id] [sys].[int] IDENTITY(1,1) NOT NULL,
    [zaehlpunktbezeichnung] nvarchar(75) COLLATE Latin1_General_CI_AS NULL,
    [log_id] [sys].[int] NULL,
    CONSTRAINT [PK_zaehlpunkte] PRIMARY KEY CLUSTERED ([id] ASC)
);