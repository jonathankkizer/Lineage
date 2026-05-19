WITH provider_staff AS (
    SELECT *, 'provider_staff' AS warehouse_staff_type
    FROM dw_dev.dev_jkizer.intmdt_rippling_provider_staff
),
clinical_staff AS (
    SELECT *, 'FALSE' AS is_actively_seeing_patients, 'clinical_staff' AS warehouse_staff_type
    FROM dw_dev.dev_jkizer.intmdt_rippling_clinical_staff
),
support_staff AS (
    SELECT *, 'FALSE' AS is_actively_seeing_patients, 'support_staff' AS warehouse_staff_type
    FROM dw_dev.dev_jkizer.intmdt_rippling_support_staff
),
combined_staff AS (
    SELECT * FROM provider_staff
    UNION ALL
    SELECT * FROM clinical_staff
    UNION ALL
    SELECT * FROM support_staff
),
-- Flag duplicates and assign row numbers
staff_with_duplicates AS (
    SELECT
        *,
        COUNT(*) OVER (PARTITION BY work_email) AS email_count,
        ROW_NUMBER() OVER (
            PARTITION BY work_email
            ORDER BY CASE WHEN is_active = 'TRUE' THEN 1 ELSE 2 END
        ) AS rn
    FROM combined_staff
)
-- Keep unique rows and only one row for duplicates
SELECT *
FROM staff_with_duplicates
WHERE email_count = 1 OR rn = 1