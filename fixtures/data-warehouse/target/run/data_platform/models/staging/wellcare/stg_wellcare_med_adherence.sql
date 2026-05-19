
  create or replace   view dw_dev.dev_jkizer_staging.stg_wellcare_med_adherence
  
  copy grants
  
  
  as (
    with process_wellcare_staging as (
    select
        left(Subscriber,charindex('-',Subscriber)-1) as member_id,
        Measure as measure_type,
        Measure2 as measure_type_description,
        "IN-PLAY & UNATTAINABLE" as member_status,
        case 
            when "COMPLIANCE STATUS" = 'Compliant' then 'CLOSED'
            when "COMPLIANCE STATUS" = 'Non-Compliant' then 'OPEN'
            when "COMPLIANCE STATUS" >= 0.80 then 'CLOSED'
            when "COMPLIANCE STATUS" <= 0.80 then 'OPEN' 
            else 'CLOSED'
        end as measure_status,
        coalesce(Measure2, "COMPLIANCE DETAIL") as measure_detail,
        "MED %" as med_perc,
        "30TO90" as thirty_to_ninety,
        try_to_number(regexp_replace("MAX DAYS", '[^0-9]', '')) as max_days,
        

iff(
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_filename, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_filename, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_filename, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_filename, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_filename, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_filename, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_filename, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_filename, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_filename, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
) is null or year(
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_filename, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_filename, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_filename, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_filename, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_filename, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_filename, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_filename, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_filename, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_filename, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
)) between 2015 and 2035,
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(src_filename, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(src_filename, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(src_filename, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(src_filename, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(src_filename, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(src_filename, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(src_filename, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(src_filename, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(src_filename, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(src_filename, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
),
    null
)
 as report_date,
        src_filename as src_file_name,
    from source_prod.wellcare.src_wellcare_quality_gaps_excel
    where Subscriber is not null
    and lower(Measure) like '%med adherence%'
), med_adh_data as (
    select 
        member_id,
        date_from_parts(year(report_date), '01', '01') as measure_year,
        svh_qm.quality_measure,
        svh_qm.quality_measure_type,
        svh_qm.measure_weight,
        pws.measure_type as payer_quality_measure,
        iff(svh_qm.quality_measure is null, false, true) as payer_suvida_measure_match,
        measure_status,
        member_status,
        measure_detail,
        med_perc,
        thirty_to_ninety,
        max_days,
        report_date,
        'Wellcare/Centene' as source,
        src_file_name,
    from process_wellcare_staging pws
    left join dw_dev.dev_jkizer_staging.stg_star_payer_measure_names svh_qm
        on pws.measure_type = svh_qm.payer_measure_name
        and svh_qm.payer_name = 'Wellcare/Centene'
), legacy_data as (
    select
        member_id as member_id,
        quality_measure,
        quality_measure_type,
        measure_weight,
        payer_quality_measure,
        payer_suvida_measure_match,
        measure_detail,
        iff(quality_measure like 'Med%' and not ( measure_detail like 'Last Fill%'), 0, 1) as is_single_fill,
        to_varchar(split(measure_detail, '.')[0]) as rx_name,
        to_varchar(null) as rx_number,
        wc.member_status,
        to_decimal(med_perc, 5, 4)*100 as perc_days_covered,
        iff(thirty_to_ninety is not null, 1, 0) as ninety_day_opportunity,
        max_days as gap_days_remaining,
        to_varchar(null) as prescriber_name,
        to_varchar(null) as prescriber_phone,
        to_date(null) as last_fill_date,
        to_number(null) as last_fill_day_supply,
        to_date(null) as next_refill_due,
        to_number(null) as refills_remaining,
        to_varchar(null) as rx_tier,
        to_date(null) as first_fill_date,
        to_number(null) as number_of_fills,
        to_varchar(null) as pharmacy_name,
        to_varchar(null) as pharmacy_phone,
        to_varchar(null) as pharmacy_address,
        report_date,
        measure_year,
        src_file_name,
        null as claim_reversal,
    from med_adh_data wc
    where quality_measure in ('Med Adherence - RAS','Med Adherence - Diabetes','Med Adherence - Statins')
    
    union all
    
    select
        member_id as member_id,
        quality_measure,
        quality_measure_type,
        measure_weight, 
        measure as payer_quality_measure,
        iff(svh_qm.quality_measure is null, false, true) as payer_suvida_measure_match,
        compliance__detail as measure_detail,
        iff(quality_measure like 'Med%' and not ( measure_detail like 'Last Fill%'), 0, 1) as is_single_fill,
        to_varchar(split(measure_detail, '.')[0]) as rx_name,
        to_varchar(null) as rx_number,
        null as member_status,
        case
            when "COMPLIANCE/MEASURE STATUS" like '%Compliant%' then 99
            when "COMPLIANCE/MEASURE STATUS" like '%Unattainable%' then 30
            else round(regexp_substr(compliance__detail, '\\d{1,3}(\\.\\d+)?'), 0) end
        as perc_days_covered,
        null as ninety_day_opportunity,
        null as gap_days_remaining,
        to_varchar(null) as prescriber_name,
        to_varchar(null) as prescriber_phone,
        to_date(service_end_date) as last_fill_date,
        to_number(null) as  last_fill_day_supply,
        to_date(null) as next_refill_due,
        to_number(null) as refills_remaining,
        to_varchar(null) as rx_tier,
        to_date(service_start_date) as first_fill_date,
        to_number(null) as number_of_fills,
        to_varchar(null) as pharmacy_name,
        to_varchar(null) as pharmacy_phone,
        to_varchar(null) as pharmacy_address,
        eligibility_thru_date as report_date,
        date_trunc(year, service_end_date) as measure_year,
        src_file_name,
        null as claim_reversal,
    from source_prod.wellcare.src_wellcare_quality_2024_2 qra
    left join dw_dev.dev_jkizer_staging.stg_star_payer_measure_names svh_qm
        on qra.measure = svh_qm.payer_measure_name
        and svh_qm.payer_name = 'Wellcare/Centene'
    where lower(measure) like '%med adh%'
    -- Historical data up to 11/2024. Afterwards, started using src_wellcare_med_adherence for latest data
    and report_date <= '2024-11-01' 
    ) 
select 
    *,
    'full_report' as report_type,
from legacy_data

union all

-- Historical only: airbyte_wellcare_tx feed is frozen. New data flows through stg_wellcare_national_med_adherence.
select
    coalesce(data:Member_ID::varchar, data:Subscriber_ID::varchar, data:SUBSCRIBER_ID::varchar, data:MEMBER_ID::varchar) as member_id,
    svh_qm.quality_measure,
    svh_qm.quality_measure_type,
    svh_qm.measure_weight,
    coalesce(data:Measure_Key::varchar, data:MEASURE_KEY::varchar) as payer_quality_measure,
    iff(svh_qm.quality_measure is null, false, true) as payer_suvida_measure_match,
    concat(coalesce(data:Compliance_Detail::varchar, data:COMPLIANCE_DETAIL::varchar), ' | ', coalesce(data:Label_Name::varchar, data:LABEL_NAME::varchar)) as measure_detail,
    0 as is_single_fill,
    coalesce(data:Label_Name::varchar, data:LABEL_NAME::varchar) as rx_name,
    coalesce(data:Last_Fill_RxNumber::varchar, data:LAST_FILL_RXNUMBER::varchar) as rx_number,
    coalesce(data:Compliance_Status::varchar, data:COMPLIANCE_STATUS::varchar) as member_status,
    coalesce(data:P_DaysCovered::float, data:P_DAYSCOVERED::float) as perc_days_covered,
    iff(coalesce(data:Last_Fill_Days_Supply::number, data:LAST_FILL_DAYS_SUPPLY::number) >= 90, 0, 1) as ninety_day_opportunity,
    coalesce(data:Days_to_NonAdh::number, data:DAYS_TO_NONADH::number) as gap_days_remaining,
    concat(coalesce(data:Last_Fill_Prescriber_First_Name::varchar, data:LAST_FILL_PRESCRIBER_FIRST_NAME::varchar), ' ', coalesce(data:Last_Fill_Prescriber_Last_Name::varchar, data:LAST_FILL_PRESCRIBER_LAST_NAME::varchar)) as prescriber_name,
    coalesce(data:Prescriber_Phone_Number::varchar, data:PRESCRIBER_PHONE_NUMBER::varchar) as prescriber_phone,
    try_to_date(coalesce(data:Last_Fill_Refill_Date::varchar, data:LAST_FILL_REFILL_DATE::varchar)) as last_fill_date,
    coalesce(data:Last_Fill_Days_Supply::number, data:LAST_FILL_DAYS_SUPPLY::number) as last_fill_day_supply,
    try_to_date(coalesce(data:Next_Fill_Due_Date::varchar, data:NEXT_FILL_DUE_DATE::varchar)) as next_refill_due,
    coalesce(data:Athrzd_Refill_Left::varchar, data:ATHRZD_REFILL_LEFT::varchar) as refills_remaining,
    null as rx_tier,
    try_to_date(coalesce(data:Member_Fill1::varchar, data:MEMBER_FILL1::varchar)) as first_fill_date,
    null as number_of_fills,
    coalesce(data:Pharmacy_Name::varchar, data:PHARMACY_NAME::varchar) as pharmacy_name,
    coalesce(data:Pharmacy_Phone_Number::varchar, data:PHARMACY_PHONE_NUMBER::varchar) as pharmacy_phone,
    concat(coalesce(data:Pharmacy_Address_1::varchar, data:PHARMACY_ADDRESS_1::varchar), ' ', coalesce(data:Pharmacy_City::varchar, data:PHARMACY_CITY::varchar), ' ', coalesce(data:Pharmacy_State::varchar, data:PHARMACY_STATE::varchar)) as pharmacy_address,
    

iff(
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
) is null or year(
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
)) between 2015 and 2035,
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
),
    null
)
 as report_date,
    date_trunc('year', 

iff(
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
) is null or year(
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
)) between 2015 and 2035,
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
),
    null
)
) as report_year,
    replace(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '_SUVIDA 882864363_SUVIDA 882864363.parquet', '_SUVIDA 882864363.xlsx') as src_file_name,
    coalesce(data:Claim_Reversal::varchar, data:CLAIM_REVERSAL::varchar) as claim_reversal,
    'full_report' as report_type,
from airbyte_source_prod.wellcare_tx.quality_med_adherence_full wma
left join dw_dev.dev_jkizer_staging.stg_star_payer_measure_names svh_qm
    on coalesce(data:Measure_Key::varchar, data:MEASURE_KEY::varchar) = svh_qm.payer_measure_name
    and svh_qm.payer_name = 'Wellcare/Centene'
where last_fill_date != '1970-01-01'

union all

-- Historical only: airbyte_wellcare_tx feed is frozen. New data flows through stg_wellcare_national_med_adherence.
select
    coalesce(data:Member_ID::varchar, data:Subscriber_ID::varchar, data:SUBSCRIBER_ID::varchar, data:MEMBER_ID::varchar) as member_id,
    svh_qm.quality_measure,
    svh_qm.quality_measure_type,
    svh_qm.measure_weight,
    coalesce(data:MEASURE_KEY::varchar, data:Measure_Key::varchar) as payer_quality_measure,
    iff(svh_qm.quality_measure is null, false, true) as payer_suvida_measure_match,
    concat(coalesce(data:LABEL_NAME::varchar, data:Label_Name::varchar), ' | ') as measure_detail,
    1 as is_single_fill,
    coalesce(data:LABEL_NAME::varchar, data:Label_Name::varchar) as rx_name,
    coalesce(data:Last_Fill_RxNumber::varchar, data:LAST_FILL_RXNUMBER::varchar) as rx_number,
    'In-Play' as member_status,
    null as perc_days_covered,
    iff(coalesce(data:LAST_FILL_DAYS_SUPPLY::number, data:Last_Fill_Days_Supply::number) >= 90, 0, 1) as ninety_day_opportunity,
    coalesce(data:Days_Left::number, data:DAYS_LEFT::number) as gap_days_remaining,
    concat(coalesce(data:LAST_FILL_PRESCRIBER_FIRST_NAME::varchar, data:Last_Fill_Prescriber_First_Name::varchar), ' ', coalesce(data:LAST_FILL_PRESCRIBER_LAST_NAME::varchar, data:Last_Fill_Prescriber_Last_Name::varchar)) as prescriber_name,
    coalesce(data:PRESCRIBER_PHONE_NUMBER::varchar, data:Prescriber_Phone_Number::varchar) as prescriber_phone,
    try_to_date(coalesce(data:MEMBER_FILL1::varchar, data:Member_Fill1::varchar)) as last_fill_date,
    coalesce(data:LAST_FILL_DAYS_SUPPLY::number, data:Last_Fill_Days_Supply::number) as last_fill_day_supply,
    try_to_date(coalesce(data:NEXT_FILL_DUE_DATE::varchar, data:Next_Fill_Due_Date::varchar)) as next_refill_due,
    coalesce(data:Athrzd_Refill_Left::varchar, data:ATHRZD_REFILL_LEFT::varchar) as refills_remaining,
    null as rx_tier,
    try_to_date(coalesce(data:MEMBER_FILL1::varchar, data:Member_Fill1::varchar)) as first_fill_date,
    null as number_of_fills,
    coalesce(data:PHARMACY_NAME::varchar, data:Pharmacy_Name::varchar) as pharmacy_name,
    coalesce(data:PHARMACY_PHONE_NUMBER::varchar, data:Pharmacy_Phone_Number::varchar) as pharmacy_phone,
    concat(coalesce(data:PHARMACY_ADDRESS_1::varchar, data:Pharmacy_Address_1::varchar), ' ', coalesce(data:PHARMACY_CITY::varchar, data:Pharmacy_City::varchar), ' ', coalesce(data:PHARMACY_STATE::varchar, data:Pharmacy_State::varchar)) as pharmacy_address,
    try_to_date(coalesce(data:Report_Ran_Date::varchar, data:REPORT_RAN_DATE::varchar)) as report_date,
    date_trunc('year', try_to_date(coalesce(data:MEMBER_FILL1::varchar, data:Member_Fill1::varchar))) as report_year,
    replace(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, ' 882864363_Single Fill.parquet', '.xlsx') as src_file_name,
    null as claim_reversal,
    'single_fill' as report_type,
from airbyte_source_prod.wellcare_tx.quality_med_adherence_single_fill wmsf
left join dw_dev.dev_jkizer_staging.stg_star_payer_measure_names svh_qm
    on coalesce(data:MEASURE_KEY::varchar, data:Measure_Key::varchar) = svh_qm.payer_measure_name
    and svh_qm.payer_name = 'Wellcare/Centene'
where last_fill_date != '1970-01-01'
  );

