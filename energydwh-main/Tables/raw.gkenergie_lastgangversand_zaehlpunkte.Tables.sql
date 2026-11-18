CREATE TABLE [raw].[gkenergie_lastgangversand_zaehlpunkte]
(
    [load_at] [sys].[datetime] NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [zaehlpunkt] varchar(33) COLLATE Latin1_General_CI_AS NULL,
    [tagvon] [sys].[int] NULL,
    [tagbis] [sys].[int] NULL
);