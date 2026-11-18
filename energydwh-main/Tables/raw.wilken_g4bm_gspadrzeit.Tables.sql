CREATE TABLE [raw].[wilken_g4bm_gspadrzeit]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [ID] decimal(19,0) NOT NULL,
    [UPDATECOUNT] decimal(10,0) NOT NULL,
    [GUELTIGAB] char(10) COLLATE Latin1_General_CI_AS NOT NULL,
    [GUELTIGBIS] char(10) COLLATE Latin1_General_CI_AS NULL,
    [GSPANSCHRIFTID] decimal(19,0) NOT NULL,
    [GSPADRESSEID] decimal(19,0) NOT NULL
);