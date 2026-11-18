CREATE TABLE [dbo].[timeseries]
(
    [id] [sys].[bigint] IDENTITY(1,1) NOT NULL,
    [timestamp] [sys].[datetime] NULL,
    [zaehlpunkt_id] [sys].[int] NULL,
    [value] decimal(18,5) NULL,
    [log_id] [sys].[int] NULL,
    CONSTRAINT [PK_timeseries] PRIMARY KEY CLUSTERED ([id] ASC)
);