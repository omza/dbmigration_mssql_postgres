CREATE TABLE [raw].[wilken_ensztp]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [SZTP_NR] decimal(5,0) NOT NULL,
    [ENE_ID] decimal(2,0) NULL,
    [SZTP_BEZEICHNUNG] varchar(80) COLLATE Latin1_General_CI_AS NOT NULL,
    [SZTP_TYPCODE] varchar(3) COLLATE Latin1_General_CI_AS NULL,
    [SZTP_GROESSECODE] varchar(35) COLLATE Latin1_General_CI_AS NULL,
    [SZTP_EDIMASTER] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [SZTP_CODEINTERN] varchar(17) COLLATE Latin1_General_CI_AS NULL,
    [SZTP_ANGELEGT] [sys].[datetime] NOT NULL,
    [SZTP_GEAENDERT] [sys].[datetime] NULL,
    [SZTP_UNTERTYPCODE] varchar(3) COLLATE Latin1_General_CI_AS NULL,
    [SZTP_AKTIV] char(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [SZTP_ULA_GERAETEART] decimal(3,0) NULL,
    [SZTP_RUECKSTELLUNG] char(1) COLLATE Latin1_General_CI_AS NULL,
    [SZTP_RUECKSTELLMONAT] decimal(2,0) NULL,
    [SZTP_RUECKSTELLTAG] decimal(2,0) NULL
);