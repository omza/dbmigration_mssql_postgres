CREATE TABLE [raw].[wilken_g4bm_anrede]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [ID] decimal(19,0) NOT NULL,
    [UPDATECOUNT] decimal(10,0) NOT NULL,
    [KONZERN] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [MANDANT] char(2) COLLATE Latin1_General_CI_AS NOT NULL,
    [WERK] char(2) COLLATE Latin1_General_CI_AS NOT NULL,
    [ANREDESCHLUESSEL] char(3) COLLATE Latin1_General_CI_AS NOT NULL,
    [BEZEICHNUNG] varchar(40) COLLATE Latin1_General_CI_AS NULL,
    [CREATIONUSER] varchar(20) COLLATE Latin1_General_CI_AS NOT NULL,
    [CREATIONDATETIME] char(19) COLLATE Latin1_General_CI_AS NOT NULL,
    [CHANGEUSER] varchar(20) COLLATE Latin1_General_CI_AS NULL,
    [CHANGEDATETIME] char(19) COLLATE Latin1_General_CI_AS NULL
);