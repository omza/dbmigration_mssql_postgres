CREATE TABLE [raw].[wilken_ensvba]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [SVBA_NR] decimal(5,0) NOT NULL,
    [SVBA_BEZEICHNUNG] varchar(80) COLLATE Latin1_General_CI_AS NOT NULL
);