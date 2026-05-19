
  create or replace   view dw_dev.dev_jkizer_staging.stg_united_az_census
  
  copy grants
  
  
  as (
    WITH united_tucson_census AS (
    SELECT
        patient_no AS source_member_id,
        TRY_CAST(AdmitDate AS DATE) AS admit_date,
        TRY_CAST(DischargeDate AS DATE) AS discharge_date,
        Phys_Attend_Name AS attending_physician,
        FULL_NM AS pcp,
        CASE
            WHEN Treatmt_Setting_SubType IN ('Acute Hospital') THEN 'inpatient'
            WHEN Treatmt_Setting_SubType IN ('SNF', 'Skilled nursing fac') THEN 'skilled_nursing'
            ELSE NULL
        END AS level_of_care,
        Hosp_Name AS facility,
        dx_prim AS dx_code,
        Dx_Desc AS dx_text,
        src_file_name,
        

iff(
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_file_name, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_file_name, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_file_name, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_file_name, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_file_name, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_file_name, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
) is null or year(
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_file_name, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_file_name, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_file_name, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_file_name, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_file_name, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_file_name, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
)) between 2015 and 2035,
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_file_name, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_file_name, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_file_name, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_file_name, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_file_name, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_file_name, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
),
    null
)
 AS report_date,
        'United' AS source,
        'sftp' as source_type,
    FROM SOURCE_PROD.united.src_united_tucson_census
),
united_phoenix_census AS (
    SELECT
        patient_no AS source_member_id,
        TRY_CAST(AdmitDate AS DATE) AS admit_date,
        TRY_CAST(DischargeDate AS DATE) AS discharge_date,
        Phys_Attend_Name AS attending_physician,
        Phys_PCP_Name AS pcp,
        CASE
            WHEN Treatmt_Setting_SubType IN ('Acute Hospital') THEN 'inpatient'
            WHEN Treatmt_Setting_SubType IN ('SNF', 'Skilled nursing fac') THEN 'skilled_nursing'
            ELSE NULL
        END AS level_of_care,
        Hosp_Name AS facility,
        dx_prim AS dx_code,
        Dx_Desc AS dx_text,
        src_file_name,
        

iff(
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_file_name, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_file_name, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_file_name, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_file_name, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_file_name, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_file_name, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
) is null or year(
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_file_name, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_file_name, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_file_name, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_file_name, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_file_name, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_file_name, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
)) between 2015 and 2035,
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_file_name, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_file_name, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_file_name, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_file_name, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_file_name, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_file_name, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
),
    null
)
 as report_date,
        'United' AS source,
        'sftp' as source_type,
    FROM SOURCE_PROD.united.src_united_phoenix_census
),
united_practice_assist_census AS (
    SELECT
        case
            when len("SUBSCRIBER ID") = 7 then to_varchar("SUBSCRIBER ID") || '01'
            when len("SUBSCRIBER ID") = 6 then '0' || to_varchar("SUBSCRIBER ID") || '01'
            else to_varchar("SUBSCRIBER ID")
        end as source_member_id,
        TRY_CAST("ADMIT DATE" AS DATE) AS admit_date,
        TRY_CAST("Discharge Date" AS DATE) AS discharge_date,
        null as attending_physician,
        "PRIMARY CARE PROVIDER NAME" AS pcp,
        CASE
            WHEN "EVENT TYPE" LIKE '%INPATIENT%' THEN 'inpatient'
            WHEN "EVENT TYPE" LIKE '%EMERGENCY MEDICINE%' THEN 'emergency'
            ELSE NULL
        END AS level_of_care,
        "ADMITTING HOSPITAL" AS facility,
        null as dx_code,
        null as dx_text,
        src_file_name,
        

iff(
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_file_name, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_file_name, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_file_name, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_file_name, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_file_name, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_file_name, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
) is null or year(
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_file_name, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_file_name, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_file_name, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_file_name, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_file_name, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_file_name, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
)) between 2015 and 2035,
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_file_name, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_file_name, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_file_name, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_file_name, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_file_name, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_file_name, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_file_name, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_file_name, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
),
    null
)
 AS report_date,
        'United' AS source,
        'portal' as source_type,
    from SOURCE_PROD.united.SRC_UNITED_PRACTICE_ASSIST_CENSUS
),

united_dsnp_census AS (
    SELECT
        case
            when len(data:"patient_no"::string) = 7 then to_varchar(data:"patient_no"::string) || '01'
            when len(data:"patient_no"::string) = 6 then '0' || to_varchar(data:"patient_no"::string) || '01'
            else to_varchar(data:"patient_no"::string)
        end as source_member_id,
        TRY_CAST(data:"AdmitDate"::string AS DATE) AS admit_date,
        TRY_CAST(data:"DischargeDate"::string AS DATE) AS discharge_date,
        data:"Phys_Attend_Name"::string AS attending_physician,
        data:"Phys_PCP_Name"::string AS pcp,
        CASE
            WHEN data:"Treatmt_Setting_SubType"::string IN ('Acute Hospital') THEN 'inpatient'
            WHEN data:"Treatmt_Setting_SubType"::string IN ('SNF', 'Skilled nursing fac') THEN 'skilled_nursing'
            ELSE NULL
        END AS level_of_care,
        data:"Hosp_Name"::string AS facility,
        data:"dx_prim"::string AS dx_code,
        data:"Dx_Desc"::string AS dx_text,
        replace(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '_IPDetail.parquet', '.xlsx') as src_file_name,
        

iff(
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
) is null or year(
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
)) between 2015 and 2035,
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
),
    null
)
 AS report_date,
        'United' AS source,
        'sftp' as source_type,
    FROM airbyte_source_prod.united_az.united_census_dsnprpt
),

united_hospital_census AS (
    SELECT
        case
            when len(data:"Subscriber Id"::string) = 7 then data:"Subscriber Id"::string || '01'
            when len(data:"Subscriber Id"::string) = 6 then '0' || data:"Subscriber Id"::string || '01'
            else data:"Subscriber Id"::string
        end as source_member_id,
        TRY_TO_DATE(data:"Admit Date"::string, 'MM/DD/YYYY') AS admit_date,
        TRY_TO_DATE(data:"Discharge Date"::string, 'MM/DD/YYYY') AS discharge_date,
        null as attending_physician,
        data:"Primary Care Provider Name"::string AS pcp,
        CASE
            WHEN data:"Event Type"::string LIKE '%INPATIENT%' THEN 'inpatient'
            WHEN data:"Event Type"::string LIKE '%EMERGENCY MEDICINE%' THEN 'emergency'
            ELSE NULL
        END AS level_of_care,
        data:"Admitting Hospital"::string AS facility,
        null as dx_code,
        null as dx_text,
        split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar as src_file_name,
        try_to_date(
            left(regexp_substr(
                split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-1]::varchar,
                '\\d+'
            ), 8),
            'MMDDYYYY'
        ) AS report_date,
        'United' AS source,
        'portal' as source_type,
    FROM airbyte_source_prod.united_az.census_hospital_export
),

combined as (
    select * from united_tucson_census
    union all
    select * from united_phoenix_census
    union all
    select * from united_practice_assist_census
    union all
    select * from united_dsnp_census
    union all
    select * from united_hospital_census
)

select * from combined
where source_member_id is not null
  );

