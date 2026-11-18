CREATE TABLE [raw].[power_switch_power_ipuep_saga]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [key] [sys].[int] NOT NULL,
    [id] [sys].[int] NOT NULL,
    [date_1] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [date_2] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [date_3] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [device] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [type] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [card] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [customer] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    [leistung] varchar(45) COLLATE Latin1_General_CI_AS NULL,
    CONSTRAINT [pk_power_switch_power_ipuep_saga] PRIMARY KEY CLUSTERED ([key] ASC)
);