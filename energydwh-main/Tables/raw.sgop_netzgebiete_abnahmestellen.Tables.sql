CREATE TABLE [raw].[sgop_netzgebiete_abnahmestellen]
(
    [Straße] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [HausNr] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [UnterhausNr] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Lage] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [Netzgebiet] nvarchar(50) COLLATE Latin1_General_CI_AS NULL,
    [id_abn] [sys].[int] NULL,
    [abnahmestelle_status] [sys].[int] NULL,
    [abnahmestelle_straße] varchar(70) COLLATE Latin1_General_CI_AS NULL,
    [abnahmestelle_hausnummer] [sys].[int] NULL,
    [abnahmestelle_hausnummer_zusatz] varchar(30) COLLATE Latin1_General_CI_AS NULL,
    [abnahmestelle_plz] varchar(10) COLLATE Latin1_General_CI_AS NULL,
    [abnahmestelle_ort] varchar(40) COLLATE Latin1_General_CI_AS NULL
);