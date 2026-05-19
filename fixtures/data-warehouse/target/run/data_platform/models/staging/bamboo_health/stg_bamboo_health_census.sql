
  create or replace   view dw_dev.dev_jkizer_staging.stg_bamboo_health_census
  
  copy grants
  
  
  as (
    select
    -- Airbyte metadata
    _airbyte_raw_id,
    _airbyte_extracted_at,
    _airbyte_meta,
    _ab_source_file_url,
    _ab_source_file_last_modified,
    split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar as src_file_name,
    coalesce(
        

iff(
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
) is null or year(
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
)) between 2015 and 2035,
    
coalesce(
    -- 1. YYYY-MM-DD (ISO format - most specific)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{4}-\\d{2}-\\d{2}'), 'YYYY-MM-DD'),

    -- 2. YYYY_MM_DD (underscore separated)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{4}_\\d{2}_\\d{2}'), 'YYYY_MM_DD'),

    -- 3. MM_DD_YYYY (underscore separated US format)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}_\\d{1,2}_\\d{4}'), 'MM_DD_YYYY'),

    -- 4. YYYYMMDD (8 digits starting with 19 or 20 for year validation)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '(19|20)\\d{6}'), 'YYYYMMDD'),

    -- 5. MM-DD-YYYY (US format with dashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}-\\d{1,2}-\\d{4}'), 'MM-DD-YYYY'),

    -- 6. MM.DD.YYYY (US format with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{4}'), 'MM.DD.YYYY'),

    -- 7. MM/DD/YYYY (US format with slashes)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}/\\d{1,2}/\\d{4}'), 'MM/DD/YYYY'),

    -- 8. DD-Mon-YYYY (e.g., 15-Jan-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{4}', 1, 1, 'i'), 'DD-MON-YYYY'),

    -- 9. DDMonYYYY (e.g., 15Jan2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{4}', 1, 1, 'i'), 'DDMONYYYY'),

    -- 10. Mon-DD-YYYY (e.g., Jan-15-2025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-\\d{1,2}-\\d{4}', 1, 1, 'i'), 'MON-DD-YYYY'),

    -- 11. MonDDYYYY (e.g., Jan152025)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\d{1,2}\\d{4}', 1, 1, 'i'), 'MONDDYYYY'),

    -- 12. MMDDYYYY (8 digits, month-first - more ambiguous, so later in order)
    -- Only try this if the first 2 digits are 01-12 (valid month)
    try_to_date(
        iff(
            try_to_number(left(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{8}'), 2)) between 1 and 12
            and try_to_number(substr(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{8}'), 3, 2)) between 1 and 31,
            regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{8}'),
            null
        ),
        'MMDDYYYY'
    ),

    -- 13. MM-DD-YY (2-digit year with dashes)
    -- Note: 4-digit year patterns above will match first, so this is safe
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}-\\d{1,2}-\\d{2}'), 'MM-DD-YY'),

    -- 14. MM.DD.YY (2-digit year with dots)
    try_to_date(regexp_substr(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/')) - 1]::varchar, '\\d{1,2}\\.\\d{1,2}\\.\\d{2}'), 'MM.DD.YY')
),
    null
)
,
        try_to_date(data['Event Processed Date']::varchar, 'MM/DD/YYYY')
    ) as report_date,

    -- Patient identity
    data['Patient ID']::varchar as patient_id,
    data['First Name']::varchar as first_name,
    data['Last Name']::varchar as last_name,
    data['Middle Name']::varchar as middle_name,
    data['Suffix']::varchar as suffix,
    try_to_date(data['DOB']::varchar, 'MM/DD/YYYY') as date_of_birth,
    data['Gender']::varchar as gender,
    data['Race']::varchar as race,
    data['Ethnicity']::varchar as ethnicity,
    data['Language']::varchar as language,
    data['Marital Status']::varchar as marital_status,
    data['Veteran Status']::varchar as veteran_status,

    -- Patient address
    data['Address 1']::varchar as address_1,
    data['Address 2']::varchar as address_2,
    data['Address 3']::varchar as address_3,
    data['City']::varchar as city,
    data['State']::varchar as state,
    data['Zip']::varchar as zip,

    -- Patient phone
    data['Home Phone']::varchar as home_phone,
    data['Mobile Phone']::varchar as mobile_phone,
    data['Patient Phone Number (Unknown source)']::varchar as patient_phone_unknown,

    -- Visit
    data['Visit ID']::varchar as visit_id,
    data['Account Number']::varchar as account_number,
    data['Status']::varchar as status,
    try_to_date(data['Status Date']::varchar, 'MM/DD/YYYY') as status_date,
    data['Status Time']::varchar as status_time,
    data['Setting']::varchar as setting,
    data['Facility Type']::varchar as facility_type,
    data['LOS']::varchar as los,
    data['Visit Duration (days)']::varchar as visit_duration_days,
    data['Entry Delay']::varchar as entry_delay,
    data['Facility Visit Id']::varchar as facility_visit_id,

    -- Facility
    data['Facility Name']::varchar as facility_name,
    data['Facility NPI']::varchar as facility_npi,
    data['Facility City']::varchar as facility_city,
    data['Facility State']::varchar as facility_state,

    -- Diagnosis
    data['Primary Diagnosis Code']::varchar as primary_diagnosis_code,
    data['Primary Diagnosis Description']::varchar as primary_diagnosis_description,
    data['Diagnosis Category']::varchar as diagnosis_category,
    data['Subsequent Diagnosis Codes']::varchar as subsequent_diagnosis_codes,
    data['Free Text Diagnosis']::varchar as free_text_diagnosis,

    -- Discharge
    data['Discharged Disposition']::varchar as discharged_disposition,
    data['Discharge Location']::varchar as discharge_location,
    data['Discharge Care Coordinator']::varchar as discharge_care_coordinator,
    data['Admitted From']::varchar as admitted_from,

    -- Attending provider
    data['Attending Provider First Name']::varchar as attending_provider_first_name,
    data['Attending Provider Last Name']::varchar as attending_provider_last_name,
    data['Attending Provider NPI']::varchar as attending_provider_npi,

    -- Roster / PCP
    data['Roster Provider']::varchar as roster_provider,
    data['Roster Provider NPI']::varchar as roster_provider_npi,
    data['Roster Practice']::varchar as roster_practice,
    data['Roster Program']::varchar as roster_program,
    data['Active Roster Patient']::varchar as active_roster_patient,

    -- Insurance
    data['Primary Insurer']::varchar as primary_insurer,
    data['Primary Insurance Number']::varchar as primary_insurance_number,
    data['Primary Insurance Plan']::varchar as primary_insurance_plan,
    data['Insurance Billed']::varchar as insurance_billed,
    data['Secondary Insurer']::varchar as secondary_insurer,
    data['Secondary Insurance Number']::varchar as secondary_insurance_number,
    data['Secondary Insurance Plan']::varchar as secondary_insurance_plan,

    -- Bamboo operational
    data['Ping Active']::varchar as ping_active,
    data['Ping Resolution Status']::varchar as ping_resolution_status,
    try_to_date(data['Ping Resolution Date']::varchar, 'MM/DD/YYYY') as ping_resolution_date,
    data['Ping Resolution Time']::varchar as ping_resolution_time,
    data['Ping Resolution Username']::varchar as ping_resolution_username,
    data['High Utilizer Flag']::varchar as high_utilizer_flag,
    data['Readmission Risk Flag']::varchar as readmission_risk_flag,
    data['Recent Inpatient Stay Flag']::varchar as recent_inpatient_stay_flag,
    data['Recent SNF Stay Flag']::varchar as recent_snf_stay_flag,
    data['COVID-19 Flags']::varchar as covid_19_flags,
    data['CCD']::varchar as ccd,
    data['3DW']::varchar as three_dw,

    -- Next of kin
    data['Next of Kin First Name']::varchar as next_of_kin_first_name,
    data['Next of Kin Last Name']::varchar as next_of_kin_last_name,
    data['Next of Kin Phone Numbers']::varchar as next_of_kin_phone_numbers,
    data['Next of Kin Relationship']::varchar as next_of_kin_relationship,

    -- Other
    data['Other Practices']::varchar as other_practices,
    data['Other Programs']::varchar as other_programs,
    data['Other Providers']::varchar as other_providers,
    data['MLOA Disposition']::varchar as mloa_disposition,
    data['MLOA Location']::varchar as mloa_location,
    data['Disclaimer']::varchar as disclaimer,

    -- Event timing
    try_to_date(data['Event Processed Date']::varchar, 'MM/DD/YYYY') as event_processed_date,
    data['Event Processed Time']::varchar as event_processed_time,
    try_to_date(data['Event Receive Date']::varchar, 'MM/DD/YYYY') as event_receive_date,
    data['Event Receive Time']::varchar as event_receive_time,

    -- Source tracking
    'Bamboo Health' as source,
    'sftp' as source_type

from airbyte_source_prod.bamboo_health_prod.census
where data['Patient ID']::varchar is not null
  );

