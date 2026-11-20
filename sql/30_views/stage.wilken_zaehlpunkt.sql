-- Quelle: energydwh-main/Views/stage.wilken_zaehlpunkt.View.sql
-- Portierung:
--   * ORDER BY ... DESC -> DESC NULLS LAST (T-SQL sortiert NULL als kleinsten Wert)
--   * '+' -> '||' (NULL-Semantik identisch: ein NULL-Teil macht das Ergebnis NULL)
--   * CAST(x AS VARCHAR) ohne Länge = varchar(30) in T-SQL; alle betroffenen Werte sind kürzer
--   * [EnergyDWH].raw.x -> raw.x
CREATE OR REPLACE VIEW stage.wilken_zaehlpunkt AS

    WITH zpnetz AS (

        SELECT
            mnd_id,
            zpt_id,
            zpn_gueltigab,
            net_id,
            row_number() OVER (PARTITION BY mnd_id, zpt_id ORDER BY zpn_gueltigab DESC NULLS LAST) AS rang
        FROM raw.wilken_enzpn

    ), zpdaten AS (

        SELECT
            mnd_id,
            zpt_id,
            zpd_gueltigab,
            coalesce(spe_nr_entnahme, spe_nr_messung) AS spe_nr_entnahme,
            spe_nr_messung,
            zpd_anschlussleistung,
            zpd_inst_leistung,
            zpd_gasdruck,
            row_number() OVER (PARTITION BY mnd_id, zpt_id ORDER BY zpd_gueltigab DESC NULLS LAST) AS rang
        FROM raw.wilken_enzptdaten

    ), bilanzierungsdaten AS (

        SELECT
            zpt_id::integer AS zpt_id,
            mnd_id::integer AS mnd_id,
            coalesce(zvf_nr::integer, -1) AS id_zaehlverfahren,
            coalesce(lpr_id::integer, -1) AS id_lastprofil,
            row_number() OVER (PARTITION BY mnd_id, zpt_id ORDER BY zpbd_gueltigab DESC NULLS LAST) AS rang
        FROM raw.wilken_enzpbdaten

    ), messtellenbetreiber AS (

        SELECT
            zpt_id::integer AS zpt_id,
            mbt_id::integer AS id_messstellenbetreiber,
            CAST(zmb_grundzustaendig AS integer) AS grundzustaendig_messstellenbetreiber,
            zmb_gueltigab,
            zmb_gueltigbis,
            row_number() OVER (PARTITION BY zpt_id ORDER BY zmb_gueltigab DESC NULLS LAST) AS rang
        FROM raw.wilken_enzptmessstellenbetreiber
        WHERE zmb_status = 1

    )
    SELECT
        zp.mnd_id AS wilken_mnd_id,
        zp.zpt_id AS wilken_zpt_id,
        zp.zpt_meteringcode AS meteringcode,
        zp.zpt_energieart AS id_energieart,
        zp.zpt_typ AS id_zp_typ,
        abn.abn_strasse || ' ' || coalesce(abn.abn_hausnr::varchar, '') || coalesce(abn.abn_hausunternr::varchar, '')
            || ', ' || abn.abn_plz::varchar || ' ' || abn.abn_ort AS abnahmestelle_adresse,
        abn.abn_lto_nr AS ablesetour_nr,
        zp.brw_nr AS wilken_brw_nr,
        zp.zpt_ismesslokation AS wilken_zpt_ismesslokation,
        zp.zpt_komplexemessung AS wilken_zpt_komplexemessung,
        zp.zpt_angelegt AS created_at,
        zp.zpt_geaendert AS changed_at,
        abn.abn_strasse AS abnahmestelle_straße,
        abn.abn_hausnr::integer AS abnahmestelle_hausnummer,       -- numeric(5,0): kein Rundungsunterschied
        abn.abn_hausunternr AS abnahmestelle_hausnummer_zusatz,
        abn.abn_plz::varchar(10) AS abnahmestelle_plz,
        abn.abn_ort AS abnahmestelle_ort,
        abn.abn_id::integer AS id_abn,
        coalesce(netz.net_id::integer, 0) AS id_netz,
        coalesce(abn.abn_status, -1)::integer AS abnahmestelle_status,
        --
        coalesce(d.spe_nr_entnahme::integer, -1) AS id_spannungsebene,
        d.spe_nr_messung::integer AS id_spannungsebene_messung,
        d.zpd_anschlussleistung::numeric(12,3) AS anschlussleistung,
        d.zpd_inst_leistung::numeric(12,3) AS installierte_leistung,
        d.zpd_gasdruck::integer AS gasdruck_mbar,
        --
        coalesce(b.id_lastprofil, -1) AS id_lastprofil,
        coalesce(b.id_zaehlverfahren, -1) AS id_zaehlverfahren,
        --
        coalesce(mbt.id_messstellenbetreiber, -1) AS id_messstellenbetreiber,
        coalesce(mbt.grundzustaendig_messstellenbetreiber, -1) AS grundzustaendig_messstellenbetreiber

    FROM raw.wilken_enzpt zp
    JOIN raw.wilken_enabn abn
        ON zp.abn_id = abn.abn_id
    LEFT JOIN zpnetz netz
        ON zp.mnd_id = netz.mnd_id
       AND zp.zpt_id = netz.zpt_id
       AND netz.rang = 1
    LEFT JOIN zpdaten d
        ON zp.mnd_id = d.mnd_id
       AND zp.zpt_id = d.zpt_id
       AND d.rang = 1
    LEFT JOIN bilanzierungsdaten b
        ON zp.mnd_id = b.mnd_id
       AND zp.zpt_id = b.zpt_id
       AND b.rang = 1
    LEFT JOIN messtellenbetreiber mbt
        ON zp.zpt_id = mbt.zpt_id
       AND mbt.rang = 1;
