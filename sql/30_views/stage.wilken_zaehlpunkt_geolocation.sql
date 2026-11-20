-- Quelle: energydwh-main/Views/stage.wilken_zaehlpunkt_geolocation.View.sql
-- Portierung:
--   * TRY_CAST(x AS decimal(11,8)) -> util.try_decimal(x, 11, 8)
--   * CI-AUDIT: Join zp.abnahmestelle_adresse = loc.address und PARTITION BY address waren in MSSQL
--     case-insensitiv. Hier case-sensitiv belassen (Adressen stammen aus derselben Quelle);
--     Abweichungen zeigt der Parallelabgleich.
--   * row_number() ohne eindeutige Sortierung: bei gleichem location_type ist die Wahl in beiden
--     Systemen zufällig.
CREATE OR REPLACE VIEW stage.wilken_zaehlpunkt_geolocation AS

    WITH loc AS (

        SELECT
            *,
            row_number() OVER (PARTITION BY address ORDER BY
                CASE
                    WHEN location_type = 'ROOFTOP' THEN 1
                    WHEN location_type = 'RANGE_INTERPOLATED' THEN 2
                    WHEN location_type = 'GEOMETRIC_CENTER' THEN 3
                    WHEN location_type = 'APPROXIMATE' THEN 4
                    ELSE 5
                END
            ) AS best_loc
        FROM raw.address_geolocation

    )
    SELECT
        zp.id_zp,
        coalesce(util.try_decimal(loc.lat, 11, 8)::numeric(11,8), zp.abnahmestelle_lat) AS abnahmestelle_lat,
        coalesce(util.try_decimal(loc.lng, 11, 8)::numeric(11,8), zp.abnahmestelle_lon) AS abnahmestelle_lon,
        coalesce(loc.location_type, zp.abnahmestelle_location_type) AS abnahmestelle_location_type
    FROM core.zaehlpunkte zp
    LEFT JOIN loc
        ON zp.abnahmestelle_adresse = loc.address
       AND loc.best_loc = 1;
