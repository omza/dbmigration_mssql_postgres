CREATE TABLE [core].[kunde]
(
    [id_kunde] [sys].[int] IDENTITY(1,1) NOT NULL,
    [name] nvarchar(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [aktiv] [sys].[bit] CONSTRAINT [DF_kunde_aktiv] DEFAULT ((1)) NOT NULL,
    [valid_to] [sys].[datetime] CONSTRAINT [DF_kunde_vt] DEFAULT (CONVERT([datetime],'31.12.9999',(104))) NOT NULL,
    [changed_at] [sys].[datetime] CONSTRAINT [DF_kunde_ca] DEFAULT (getdate()) NULL,
    [id_gruppe] [sys].[int] NULL,
    CONSTRAINT [pk_kunde] PRIMARY KEY CLUSTERED ([id_kunde] ASC)
);

ALTER TABLE [core].[kunde]
ADD CONSTRAINT [fk_kunde_gruppe]
FOREIGN KEY ([id_gruppe])
REFERENCES [core].[gruppe] ([id_gruppe]);

CREATE NONCLUSTERED INDEX [ix_kunde_name] ON [core].[kunde] ([name] ASC) INCLUDE ([aktiv]);
