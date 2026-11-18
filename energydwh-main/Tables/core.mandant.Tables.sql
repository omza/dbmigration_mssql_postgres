CREATE TABLE [core].[mandant]
(
    [id_mandant] [sys].[int] NOT NULL,
    [mandant] varchar(40) COLLATE Latin1_General_CI_AS NOT NULL,
    [wilken_mnd_id] decimal(5,0) NOT NULL,
    [wilken_konzern] char(1) COLLATE Latin1_General_CI_AS NULL,
    [wilken_gpmandant] char(2) COLLATE Latin1_General_CI_AS NULL,
    [created_at] [sys].[datetime] CONSTRAINT [DF__mandant__created__24885067] DEFAULT (getdate()) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF__mandant__changed__257C74A0] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_mandant] PRIMARY KEY CLUSTERED ([id_mandant] ASC)
);