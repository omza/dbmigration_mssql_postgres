CREATE TABLE [raw].[wilken_enzaehlerlos]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [ZAE_ID] decimal(12,0) NOT NULL,
    [MND_ID] decimal(5,0) NOT NULL,
    [LOS_NR] varchar(20) COLLATE Latin1_General_CI_AS NOT NULL,
    [ZLO_VERLJAHR] decimal(4,0) NULL,
    [ZLO_ZAEHLERART] decimal(1,0) NOT NULL,
    [ZLO_VORGANGSART] decimal(1,0) NULL,
    [LOS_NR_ZUSATZ] decimal(2,0) NOT NULL,
    [ZLO_LFDNR] decimal(12,0) NULL,
    [ZLO_ZIEHUNGSNR] decimal(12,0) NULL
);