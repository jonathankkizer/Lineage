with assignment as (
	select
		lpad(data['Member ID']::varchar, 11, '0') as member_id, --00000340761
		to_varchar(data:MedicareNo::varchar) as medicare_beneficiary_id,
		lower(data['First Name']::varchar) as first_name,
		lower(data['Last Name']::varchar) as last_name,
		null as middle_name,
		lower(data:MI::varchar) as middle_initial,
		date(data:BirthDate::varchar, 'YYYYMMDD') as birth_date,
		
    
    case
        when regexp_replace(data:Contact_Phone::varchar, '[^0-9]', '') = '' then null
        when length(regexp_replace(data:Contact_Phone::varchar, '[^0-9]', '')) = 11
            and left(regexp_replace(data:Contact_Phone::varchar, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(data:Contact_Phone::varchar, '[^0-9]', ''), 10)
        when length(regexp_replace(data:Contact_Phone::varchar, '[^0-9]', '')) = 10
            then regexp_replace(data:Contact_Phone::varchar, '[^0-9]', '')
        else null
    end
 as phone,
		null as email,
		data['Primary Language']::varchar as language_preference,
		data:Sex::varchar as gender,
		data['Resident Address 1']::varchar as address_line_1,
		data['Resident Address 2']::varchar as address_line_2,
		data['Resident City']::varchar as city,
		data['Resident State']::varchar as state,
		data['Resident Zip']::varchar as zip,
		null as dual_status,
		null as hospice_ind,
		null as esrd_ind,
		split(data['PCP Name']::varchar, ', ')[1]::varchar as provider_first_name,
		split(data['PCP Name']::varchar, ', ')[0]::varchar as provider_last_name,
		null as pcp_npi,
		data:PCP_ID::varchar as payer_provider_id,
		null as plan_variant,
		null as agent_number,
		null as agent_info,
		'Alignment AZ' as source,
		'Alignment' as payer_parent,
		'Alignment AZ' as payer_name,
		'Alignment AZ' as payer_contract,
		

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
		split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar as src_file_name,
		date(data['PCP Eff Date']::varchar, 'YYYYMMDD') as suvida_start_date,
		'H3443' || lpad(data:PBP::varchar, 3, '0') as contract_plan_id, -- hard coding for now; current assignment doesn't give contract ID
		'H3443' || lpad(data:PBP::varchar, 3, '0') || '000' as payer_plan_code,
		data['Benefit Option']::varchar as benefit_option,
		data['PBP']::varchar as pbp_code,
		data as data_variant
	from airbyte_source_prod.alignment.assignment
	qualify row_number() over (partition by src_file_name, member_id order by suvida_start_date asc) = 1
)
select
	*,
	dense_rank() over (partition by source order by report_date desc) as report_index,
	dense_rank() over (partition by member_id order by report_date desc) as patient_report_index,
	date_trunc(month, report_date) as report_month,
	null as lob_file,
	null as source_lob,
	md5(cast(coalesce(cast(member_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as member_file_skey,
	floor((datediff(day, birth_date, current_date())) / 365.25) as age_year,
	md5(cast(coalesce(cast(provider_first_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(provider_last_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(pcp_npi as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(report_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as provider_file_skey
from assignment