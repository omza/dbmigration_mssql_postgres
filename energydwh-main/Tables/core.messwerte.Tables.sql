CREATE TABLE [core].[messwerte]
(
    [id_messpunkt] [sys].[int] NOT NULL,
    [id_obis] [sys].[int] NOT NULL,
    [messung_am] [sys].[datetime] NOT NULL,
    [bstunde] varchar(1) COLLATE Latin1_General_CI_AS NOT NULL,
    [tag] [sys].[date] NOT NULL,
    [id_typtag] [sys].[int] CONSTRAINT [DF__messwerte__id_ty__36D1E92B] DEFAULT ((0)) NOT NULL,
    [id_zeitumstellung] [sys].[int] CONSTRAINT [DF__messwerte__id_ze__37C60D64] DEFAULT ((0)) NOT NULL,
    [id_version] [sys].[int] NOT NULL,
    [messwert] decimal(15,3) NOT NULL,
    [messeinheit] varchar(5) COLLATE Latin1_General_CI_AS NOT NULL,
    [id_wertstatus] [sys].[int] NOT NULL,
    [neu_flag] [sys].[tinyint] CONSTRAINT [DF__messwerte__neu_f__38BA319D] DEFAULT ((1)) NOT NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__messwerte__creat__39AE55D6] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__messwerte__chang__3AA27A0F] DEFAULT (getdate()) NULL,
    CONSTRAINT [pk_messwerte] PRIMARY KEY CLUSTERED ([id_messpunkt] ASC, [id_obis] ASC, [messung_am] ASC, [bstunde] ASC)
);

ALTER TABLE [core].[messwerte]
ADD CONSTRAINT [fk_messwerte_messpunkt]
FOREIGN KEY ([id_messpunkt])
REFERENCES [core].[messpunkte] ([id_messpunkt]);

ALTER TABLE [core].[messwerte]
ADD CONSTRAINT [fk_messwerte_obis]
FOREIGN KEY ([id_obis])
REFERENCES [core].[obis] ([id_obis]);