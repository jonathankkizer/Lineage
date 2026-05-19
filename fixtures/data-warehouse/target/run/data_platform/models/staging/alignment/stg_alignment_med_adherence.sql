
  create or replace   view dw_dev.dev_jkizer_staging.stg_alignment_med_adherence
  
  copy grants
  
  
  as (
    -- Available source columns not currently mapped to intmdt_med_adherence fields:
--   NDC, Quantity, Missed Refill (Y/N), Pharmacy NABP, Pharmacy FAX,
--   PCP NPI, Prescriber NPI, DOB, Gender, Member Name, Member Phone#,
--   IPA, Prescription Filled Date, Success Cutoffdate

with alignment_med_adh as (
	select
		lpad(data['Member ID']::varchar, 11, '0') as member_id,
		data['Drug Type']::varchar as quality_measure,
		null as measure_detail,
		0 as is_single_fill,
		data['Drug Label Name']::varchar as rx_name,
		to_varchar(null) as rx_number,
		to_double(null) as perc_days_covered,
		iff(try_to_double(data['Days Supply']::varchar) = 30, 1, 0) as ninety_day_opportunity,
		to_double(null) as gap_days_remaining,
		to_varchar(null) as member_status,
		to_number(null) as lis_level,
		data['PCP Name']::varchar as prescriber_name,
		to_varchar(null) as prescriber_phone,
		try_to_date(data['Date Of Service']::varchar) as last_fill_date,
		try_to_double(data['Days Supply']::varchar) as last_fill_day_supply,
		try_to_date(data['Refill Due Date']::varchar) as next_refill_due,
		to_number(null) as refills_remaining,
		to_varchar(null) as rx_tier,
		date(null) as first_fill_date,
		to_number(null) as number_of_fills,
		data['Pharmacy Name']::varchar as pharmacy_name,
		data['Pharmacy Phone']::varchar as pharmacy_phone,
		to_varchar(null) as pharmacy_address,
		replace(
		  split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar,
		  '_Med Adh.parquet',
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
 as report_date,
	from airbyte_source_prod.alignment.quality_med_adh
	where data['Member ID']::varchar is not null
	qualify row_number() over (partition by member_id, quality_measure, src_file_name order by last_fill_date desc) = 1
)
select
	amad.* exclude (quality_measure),
	svh_qm.quality_measure,
	svh_qm.quality_measure_type,
	svh_qm.measure_weight,
	amad.quality_measure as payer_quality_measure,
	iff(svh_qm.quality_measure is null, false, true) as payer_suvida_measure_match,
	'full_report' as report_type,
from alignment_med_adh amad
left join dw_dev.dev_jkizer_staging.stg_star_payer_measure_names as svh_qm
	on amad.quality_measure = svh_qm.payer_measure_name
	and svh_qm.payer_name = 'Alignment AZ'
	and svh_qm.quality_measure like '%Med Adherence%'
  );

