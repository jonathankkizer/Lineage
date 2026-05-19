WITH cte_egfr AS (
    SELECT
        flr.suvida_id,
        flr.collected_date AS egfr_date,
        TRY_CAST(flr.test_value AS FLOAT) AS egfr_value
    FROM dw_dev.dev_jkizer.fct_lab_result flr
    WHERE flr.test_name IN ('EGFR', 'eGFR non Afr Amer', 'eGFRcr CKD-EPI', 'eGFR')
      AND flr.value_type = 'NM'
      AND YEAR(flr.collected_date) = YEAR(CURRENT_DATE())
      AND TRY_CAST(flr.test_value AS FLOAT) <= 59
    QUALIFY ROW_NUMBER() OVER (PARTITION BY flr.suvida_id ORDER BY flr.collected_date DESC) = 1
),
cte_pth AS (
    SELECT
        flr.suvida_id,
        flr.collected_date AS pth_date,
        flr.test_name,
        flr.test_value
    FROM dw_dev.dev_jkizer.fct_lab_result flr
    WHERE LOWER(flr.test_name) LIKE '%pth%'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY flr.suvida_id ORDER BY flr.collected_date DESC) = 1
)
SELECT
    egfr.suvida_id,
    pth.pth_date as evidence_date,
    year(pth.pth_date) as evidence_year,
    concat(pth.test_name, ': ', pth.test_value) as evidence_desc,
    CASE
        WHEN pth.pth_date IS NOT NULL THEN 1 else 0 end as suvida_numerator,
    1 as suvida_denominator,
    0 as pending_numerator,
    'Suvida - PTH' as quality_measure    
FROM cte_egfr egfr
LEFT JOIN cte_pth pth
    ON egfr.suvida_id = pth.suvida_id