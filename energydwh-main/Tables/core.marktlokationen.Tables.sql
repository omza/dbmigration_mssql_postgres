CREATE TABLE [core].[marktlokationen]
(
    [id_malo] [sys].[int] NOT NULL,
    [id_mandant] [sys].[int] NOT NULL,
    [id_zp] [sys].[int] NOT NULL,
    [id_energierichtung] [sys].[int] NULL,
    [malo] varchar(17) COLLATE Latin1_General_CI_AS NOT NULL,
    [wilken_zmlk_id] [sys].[int] NOT NULL,
    [wilken_mlk_id] [sys].[int] NOT NULL,
    [erste_mako] [sys].[datetime] NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__marktloka__creat__74A4331B] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__marktloka__chang__75985754] DEFAULT (getdate()) NULL,
    [valid_from] [sys].[datetime] CONSTRAINT [DF__marktloka__valid__768C7B8D] DEFAULT (CONVERT([datetime],'01.01.1900',(104))) NOT NULL,
    [valid_to] [sys].[datetime] CONSTRAINT [DF__marktloka__valid__77809FC6] DEFAULT (CONVERT([datetime],'31.12.9999',(104))) NOT NULL,
    [active] [sys].[int] NOT NULL,
    CONSTRAINT [pk_marktlokationen] PRIMARY KEY CLUSTERED ([id_malo] ASC, [valid_from] ASC)
);

ALTER TABLE [core].[marktlokationen]
ADD CONSTRAINT [fk_mlk_energierichtung]
FOREIGN KEY ([id_energierichtung])
REFERENCES [core].[energierichtungen] ([id_energierichtung]);

ALTER TABLE [core].[marktlokationen]
ADD CONSTRAINT [fk_mlk_mandant]
FOREIGN KEY ([id_mandant])
REFERENCES [core].[mandant] ([id_mandant]);

ALTER TABLE [core].[marktlokationen]
ADD CONSTRAINT [fk_mlk_zp]
FOREIGN KEY ([id_zp])
REFERENCES [core].[zaehlpunkte] ([id_zp]);