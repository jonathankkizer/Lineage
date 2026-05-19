with source as (

    select * from airbyte_source_prod.alignment.claims_medical

),

renamed as (

    select
        -- identifiers
        lpad(data['Member ID']::varchar, 11, '0') as member_id,
        data['Claim No']::varchar as claim_no,
        try_to_number(data['Claim Line No']::varchar) as claim_line_no,
        data['Primary Claim No']::varchar as primary_claim_no,
        data['DCN']::varchar as dcn,
        data['Reference No']::varchar as reference_no,
        data['Cross Reference ID']::varchar as cross_reference_id,
        data['Patient Acct Number']::varchar as patient_account_number,
        data['Patient Control Number']::varchar as patient_control_number,
        data['Medical Record Number']::varchar as medical_record_number,
        nullif(trim(data['Auth No.']::varchar), '') as auth_no,
        -- member
        data['Member Name']::varchar as member_name,
        try_to_date(data['Member Birth Date']::varchar, 'MM/DD/YYYY') as member_birth_date,
        try_to_date(data['Member Effective Date']::varchar, 'MM/DD/YYYY') as member_effective_date,
        try_to_date(data['Member Term Date']::varchar, 'MM/DD/YYYY') as member_term_date,
        upper(split_part(data['Member County']::varchar, ',', 0)) as member_county,
        -- ipa & pcp
        data['IPA ']::varchar as ipa_id,
        data['IPA Desc']::varchar as ipa_description,
        data['PCP ID']::varchar as pcp_id,
        data['PCP Name']::varchar as pcp_name,
        data['PCP County']::varchar as pcp_county,
        -- service provider
        data['Svc Prov ID']::varchar as svc_prov_id,
        data['Svc Prov NPI']::varchar as svc_prov_npi,
        data['Svc Prov Name']::varchar as svc_prov_name,
        data['Svc Prov Address']::varchar as svc_prov_address,
        nullif(trim(data['Svc Prov Phone']::varchar), '') as svc_prov_phone,
        data['Svc Prov FAX']::varchar as svc_prov_fax,
        data['Svc Prov Speciality']::varchar as svc_prov_specialty,
        data['Rendering/Attending Prov ID']::varchar as rendering_prov_id,
        data['Rendering/Attending Prov Name']::varchar as rendering_prov_name,
        data['Vendor ID']::varchar as vendor_id,
        data['Vendor Name']::varchar as vendor_name,
        data['Vendor Tax ID']::varchar as vendor_tax_id,
        -- dates
        try_to_date(data['From Svc Date']::varchar, 'MM/DD/YYYY') as from_svc_date,
        try_to_date(data['To Svc Date']::varchar, 'MM/DD/YYYY') as to_svc_date,
        try_to_date(nullif(data['DOS']::varchar, '0'), 'YYYYMMDD') as dos,
        try_to_date(data['Admit Date']::varchar, 'MM/DD/YYYY') as admit_date,
        try_to_date(data['Discharge Date']::varchar, 'MM/DD/YYYY') as discharge_date,
        try_to_date(data['Received Date']::varchar, 'MM/DD/YYYY') as received_date,
        try_to_date(data['Finalized Date']::varchar, 'MM/DD/YYYY') as finalized_date,
        try_to_date(data['Paid Date']::varchar, 'MM/DD/YYYY') as paid_date,
        try_to_date(concat(data['Svc Month (YYYYMM)']::varchar, '01'), 'YYYYMMDD') as svc_month,
        try_to_date(concat(data['Received Month']::varchar, '01'), 'YYYYMMDD') as received_month,
        try_to_date(concat(data['Paid Month (YYYYMM)']::varchar, '01'), 'YYYYMMDD') as paid_month,
        -- claim details
        data['Claim Type']::varchar as claim_type,
        data['Bill Type']::varchar as bill_type,
        data['Service Type']::varchar as service_type,
        try_to_number(data['Line Status']::varchar) as line_status,
        data['Line Flag']::varchar as line_flag,
        try_to_number(data['Freq Code']::varchar) as freq_code,
        try_to_number(data['POS']::varchar) as pos,
        try_to_number(data['PBP']::varchar) as pbp,
        try_to_number(data['ICD Qualifier']::varchar) as icd_qualifier,
        try_to_double(data['Service Units']::varchar) as service_units,
        data['Adjust Code']::varchar as adjust_code,
        data['Contract']::varchar as contract,
        data['Financial Resp.']::varchar as financial_responsibility,
        data['Pay Responsibility Ind']::varchar as pay_responsibility_ind,
        data['Processing Status Code']::varchar as processing_status_code,
        data['Provider Network']::varchar as provider_network,
        data['Patient Discharge Status']::varchar as patient_discharge_status,
        data['Employer Group #']::varchar as employer_group,
        try_to_number(data['Check No']::varchar) as check_no,
        try_to_number(data['S. No.']::varchar) as sequence_number,
        nullif(trim(data['Submitter Name']::varchar), '') as submitter_name,
        data['Source']::varchar as claims_source,
        -- diagnosis
        data['Diag Code1']::varchar as diag_code_1,
        data['Diag Code2']::varchar as diag_code_2,
        data['Diag Code3']::varchar as diag_code_3,
        data['Diag Code4']::varchar as diag_code_4,
        data['Diag Code Desc1']::varchar as diag_code_desc_1,
        data['Diag Code Desc2']::varchar as diag_code_desc_2,
        data['Diag Code Desc3']::varchar as diag_code_desc_3,
        data['Diag Code Desc4']::varchar as diag_code_desc_4,
        data['DRG Code']::varchar as drg_code,
        data['DRG Code Desc']::varchar as drg_code_desc,
        -- procedure
        data['Proc Code']::varchar as proc_code,
        data['Proc Code Desc']::varchar as proc_code_desc,
        data['Proc Code Modifier']::varchar as proc_code_modifier,
        data['Rev Code']::varchar as rev_code,
        data['Rev Code Desc']::varchar as rev_code_desc,
        data['NDC Code']::varchar as ndc_code,
        -- financials
        try_to_double(replace(replace(data['Billing Charges']::varchar, '$', ''), ',', '')) as billing_charges,
        try_to_double(replace(replace(data['Paid Amt']::varchar, '$', ''), ',', '')) as paid_amt,
        try_to_double(replace(replace(data['Member Paid Amt']::varchar, '$', ''), ',', '')) as member_paid_amt,
        try_to_double(replace(replace(data['Co-Insurance']::varchar, '$', ''), ',', '')) as co_insurance,
        try_to_double(replace(replace(data['Co-Pay']::varchar, '$', ''), ',', '')) as co_pay,
        try_to_double(replace(replace(data['Deductible Amt']::varchar, '$', ''), ',', '')) as deductible_amt,
        try_to_double(replace(replace(data['HealthPlan Paid Amt']::varchar, '$', ''), ',', '')) as health_plan_paid_amt,
        try_to_double(replace(replace(data['HealthPlan Contract Value']::varchar, '$', ''), ',', '')) as health_plan_contract_value,
        try_to_double(replace(replace(data['Interest Paid Amt']::varchar, '$', ''), ',', '')) as interest_paid_amt,
        try_to_double(replace(replace(data['WithHold Amt']::varchar, '$', ''), ',', '')) as withhold_amt,
        try_to_double(replace(replace(data['Total Claim Line Cost']::varchar, '$', ''), ',', '')) as total_claim_line_cost,
        -- metadata
        regexp_replace(
            split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar,
            '_[^_]+\\.parquet$',
            '.xlsx'
        ) as src_file_name,
        

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
 as src_file_date,
        md5(cast(coalesce(cast(claim_no as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(claim_line_no as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as claim_id,
        row_number() over (partition by claim_id order by src_file_date desc) as claim_id_rank,
        'Alignment AZ' as source,
        _airbyte_extracted_at as airbyte_extracted_at
    from source
    where member_id is not null
    --and src_file_name not ilike 'test%' -- filter out test files. will be in effect after we receive the first production file.

)

select * from renamed