CREATE TABLE [core].[messwerte_tag]
(
    [id_messpunkt] [sys].[int] NOT NULL,
    [id_energieart] [sys].[int] NOT NULL,
    [id_obis] [sys].[int] NOT NULL,
    [messeinheit] varchar(5) COLLATE Latin1_General_CI_AS NOT NULL,
    [tag] [sys].[date] NOT NULL,
    [id_typtag] [sys].[int] CONSTRAINT [DF__messwerte__id_ty__3EBD23B6] DEFAULT ((0)) NOT NULL,
    [id_zeitumstellung] [sys].[int] CONSTRAINT [DF__messwerte__id_ze__3FB147EF] DEFAULT ((0)) NOT NULL,
    [id_version] [sys].[int] NOT NULL,
    [tagesverbrauch_kWh] decimal(15,3) NULL,
    [Wert] decimal(15,3) NOT NULL,
    [id_wertstatus] [sys].[int] NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__messwerte__creat__40A56C28] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__messwerte__chang__41999061] DEFAULT (getdate()) NULL,
    CONSTRAINT [pk_messwerte_tag] PRIMARY KEY CLUSTERED ([id_messpunkt] ASC, [id_obis] ASC, [tag] ASC)
);

ALTER TABLE [core].[messwerte_tag]
ADD CONSTRAINT [fk_messwerte_tag_energiearten]
FOREIGN KEY ([id_energieart])
REFERENCES [core].[energiearten] ([id_energieart]);

ALTER TABLE [core].[messwerte_tag]
ADD CONSTRAINT [fk_messwerte_tag_obis]
FOREIGN KEY ([id_obis])
REFERENCES [core].[obis] ([id_obis]);