CREATE TABLE [raw].[address_geolocation]
(
    [MetaJob] varchar(128) COLLATE Latin1_General_CI_AS NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [address] varchar(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [lat] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [lng] varchar(50) COLLATE Latin1_General_CI_AS NULL,
    [location_type] varchar(20) COLLATE Latin1_General_CI_AS NULL
);