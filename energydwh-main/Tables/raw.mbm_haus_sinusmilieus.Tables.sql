CREATE TABLE [raw].[mbm_haus_sinusmilieus]
(
    [load_log_id] [sys].[bigint] NOT NULL,
    [load_at] [sys].[datetime] NOT NULL,
    [MB_HA_ID] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_Version] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_AD_N_Strasse] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_AD_N_HNRkomplett] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_AD_N_PLZ] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_AD_N_Ort] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_AD_N_Ortsteil] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_BA_A_Haushalt] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_SI_P_KOG] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_SI_P_PMA] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_SI_P_PER] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_SI_P_EPE] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_SI_P_ADA] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_SI_P_NOB] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_SI_P_TRA] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_SI_P_PRE] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_SI_P_HED] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_SI_P_NOK] varchar(4000) COLLATE Latin1_General_CI_AS NULL,
    [MB_HA_SI_K_DOM] varchar(4000) COLLATE Latin1_General_CI_AS NULL
);