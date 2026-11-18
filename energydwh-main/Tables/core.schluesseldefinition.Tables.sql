CREATE TABLE [core].[schluesseldefinition]
(
    [feldname] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [wert] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    [definition] varchar(50) COLLATE Latin1_General_CI_AS NOT NULL,
    CONSTRAINT [pk_schluesseldefinition] PRIMARY KEY CLUSTERED ([feldname] ASC, [wert] ASC)
);