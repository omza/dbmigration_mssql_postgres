CREATE TABLE [raw].[power_switch_power_eltek_saga]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [key] [sys].[int] NOT NULL,
    [id] [sys].[int] NOT NULL,
    [date_1] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [date_2] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [date_3] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [device] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [strom] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [spannung] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [leistung] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [leistung_day] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    CONSTRAINT [PK_power_switch_power_eltek_saga] PRIMARY KEY CLUSTERED ([key] ASC)
);