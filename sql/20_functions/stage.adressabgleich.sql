-- Quelle: energydwh-main/Programmability/Functions/stage.adressabgleich.UserDefinedFunction.sql
-- Normalisierter Adressschlüssel 'strasse;hausnr+zusatz;plz;ort'.
-- Reihenfolge der Ersetzungen 1:1 übernommen (inkl. Eigenheiten, z.B. 'ahaus' greift nie,
-- weil 'haus' vorher entfernt wird). Parameterlängen (VARCHAR(n)) werden wie in T-SQL gekürzt.
CREATE OR REPLACE FUNCTION stage.adressabgleich(
    str_name text,
    hnr      text,
    hnr_zs   text,
    plz      text,
    po_name  text
)
RETURNS text
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
AS $$
DECLARE
    v_str          text;
    v_hnr_zs       text;
    v_hnr_zs_clean text;
    v_s            text;
    v_pos          integer;
BEGIN
    ------------------------------------------------------------------
    -- 1) Straßenname normalisieren
    ------------------------------------------------------------------
    v_str := lower(btrim(left(str_name, 255), ' '));
    v_str := replace(v_str, '-v-', '-von-');
    v_str := replace(v_str, 'á', 'a');
    v_str := replace(v_str, 'é', 'e');
    v_str := replace(v_str, 'ä', 'ae');
    v_str := replace(v_str, 'ö', 'oe');
    v_str := replace(v_str, 'ü', 'ue');
    v_str := replace(v_str, 'ß', 'ss');
    v_str := replace(v_str, ' ', '');
    v_str := replace(v_str, 'strasse', 'straße');
    v_str := replace(v_str, 'str.', 'straße');
    IF right(v_str, 3) = 'str' THEN
        v_str := left(v_str, util.len(v_str) - 3) || 'straße';
    END IF;

    ------------------------------------------------------------------
    -- 2) Hausnummer + Zusatz bereinigen
    ------------------------------------------------------------------
    v_hnr_zs := left(coalesce(left(hnr, 50), '') || coalesce(left(hnr_zs, 50), ''), 50);
    v_hnr_zs_clean := lower(btrim(v_hnr_zs, ' '));
    v_hnr_zs_clean := replace(v_hnr_zs_clean, 'haus', '');
    v_hnr_zs_clean := replace(v_hnr_zs_clean, 'ahaus', '');
    v_hnr_zs_clean := replace(v_hnr_zs_clean, 'hth', '');
    v_hnr_zs_clean := replace(v_hnr_zs_clean, '/', '');
    v_hnr_zs_clean := btrim(v_hnr_zs_clean, ' ');

    ------------------------------------------------------------------
    -- 3) Ort bereinigen: ab ',', '(', 'b.', 'bei ' abschneiden
    ------------------------------------------------------------------
    v_s := lower(btrim(left(po_name, 255), ' '));
    v_pos := strpos(v_s, ',');
    IF v_pos > 0 THEN v_s := left(v_s, v_pos - 1); END IF;
    v_pos := strpos(v_s, '(');
    IF v_pos > 0 THEN v_s := left(v_s, v_pos - 1); END IF;
    v_pos := strpos(v_s, 'b.');
    IF v_pos > 0 THEN v_s := left(v_s, v_pos - 1); END IF;
    v_pos := strpos(v_s, 'bei ');
    IF v_pos > 0 THEN v_s := left(v_s, v_pos - 1); END IF;

    ------------------------------------------------------------------
    -- 4) + 5) zusammensetzen, alles außer [a-z0-9;äöüß] entfernen
    --    Der Zeichenvergleich war case-insensitiv (CHARINDEX unter CI-Collation):
    --    Großbuchstaben bleiben daher erhalten (relevant für die PLZ, die nicht lowercase ist),
    --    ebenso ²³¹ (gelten als gleich zu 2/3/1). Zeichenmenge per Abfrage gegen SQL Server ermittelt.
    ------------------------------------------------------------------
    RETURN regexp_replace(
        coalesce(v_str, '') || ';' || coalesce(v_hnr_zs_clean, '') || ';'
            || coalesce(left(plz, 20), '') || ';' || coalesce(btrim(v_s, ' '), ''),
        '[^a-zA-Z0-9;äöüßÄÖÜ²³¹]', '', 'g');
END;
$$;
