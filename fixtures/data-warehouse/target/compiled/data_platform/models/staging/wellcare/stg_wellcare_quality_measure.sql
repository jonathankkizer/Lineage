with process_wellcare_staging as (
	select
		to_varchar(left(Subscriber,charindex('-',Subscriber)-1)) as member_id,
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
		to_timestamp_ntz(

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
) as report_date,
		src_filename as src_file_name,
	from source_prod.wellcare.src_wellcare_quality_gaps_excel
	where Subscriber is not null
	and lower(Measure) not like '%med adherence%'
), wellcare_quality_qra_2024_2 as (
	select
		to_varchar(member_id) as member_id,
		to_timestamp_ntz(date_trunc(year, service_end_date)) as measure_year,
		svh_qm.quality_measure,
		svh_qm.measure_display_name,
		svh_qm.quality_measure_type,
		svh_qm.measure_weight,
		measure as payer_quality_measure,
		iff(svh_qm.quality_measure is null, false, true) as payer_suvida_measure_match,
		case
			when "COMPLIANCE/MEASURE STATUS" = 'Compliant' then 'closed'
			when "COMPLIANCE/MEASURE STATUS" = 'Non-Compliant' then 'open'
		end as measure_status,
		null as member_status,
		ARRAY_TO_STRING(ARRAY_COMPACT(ARRAY_CONSTRUCT(service_start_date, service_end_date, compliance__detail)), ' ') as measure_detail,
		null as med_perc,
		null as thirty_to_ninety,
		null as max_days,
		to_timestamp_ntz(eligibility_thru_date) as report_date,
		'Wellcare/Centene' as source,
		src_file_name,
	from source_prod.wellcare.src_wellcare_quality_2024_2 qra
	left join dw_dev.dev_jkizer_staging.stg_star_payer_measure_names svh_qm
		on qra.measure = svh_qm.payer_measure_name
		and svh_qm.payer_name = 'Wellcare/Centene'
	where star_flag = true
	and lower(measure) not like '%med adherence%'
), wellcare_quality_qra_2025_1 as (
	select
		to_varchar(data:"Member ID"::string) as member_id,
		to_timestamp_ntz(date_trunc(year, try_to_date(data:"Service End Date"::string))) as measure_year,
		svh_qm.quality_measure,
		svh_qm.measure_display_name,
		svh_qm.quality_measure_type,
		svh_qm.measure_weight,
		to_varchar(data:"Measure"::string) as payer_quality_measure,
		iff(svh_qm.quality_measure is null, false, true) as payer_suvida_measure_match,
		case
			when svh_qm.quality_measure in ('Polypharmacy: Use of Multiple Anticholinergic Medications in Older Adults', 'Concurrent Use of Opioids and Benzodiazepines') and coalesce(data:"Compliance/Measure Status"::string, data:"Measure Status"::string) = 'Compliant' then 'open'
			when svh_qm.quality_measure in ('Polypharmacy: Use of Multiple Anticholinergic Medications in Older Adults', 'Concurrent Use of Opioids and Benzodiazepines') and coalesce(data:"Compliance/Measure Status"::string, data:"Measure Status"::string) = 'Non-Compliant' then 'closed'
			when svh_qm.quality_measure not in ('Polypharmacy: Use of Multiple Anticholinergic Medications in Older Adults', 'Concurrent Use of Opioids and Benzodiazepines') and coalesce(data:"Compliance/Measure Status"::string, data:"Measure Status"::string) = 'Non-Compliant' then 'open'
			when svh_qm.quality_measure not in ('Polypharmacy: Use of Multiple Anticholinergic Medications in Older Adults', 'Concurrent Use of Opioids and Benzodiazepines') and coalesce(data:"Compliance/Measure Status"::string, data:"Measure Status"::string) = 'Compliant' then 'closed'
		end as measure_status,
		null as member_status,
		ARRAY_TO_STRING(
		  ARRAY_COMPACT(
			ARRAY_CONSTRUCT(
			  TO_TIMESTAMP_NTZ(try_to_date(data:"Service Start Date"::string)),
			  TO_TIMESTAMP_NTZ(try_to_date(data:"Service End Date"::string)),
			  NULLIF(data:"Compliance Detail"::string, 'NaN')
			)
		  ),
		  ' '
		) AS measure_detail,
		null as med_perc,
		null as thirty_to_ninety,
		null as max_days,
		to_timestamp_ntz(try_to_date(data:"Eligibility Thru Date"::string)) as report_date,
		'Wellcare/Centene' as source,
		replace(replace(split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar, '_Care Gaps.parquet', '.xlsx') , '_Member Gaps in Care.parquet', '.xlsx') as src_file_name,
	from airbyte_source_prod.wellcare_tx.quality_part_c qra
	left join dw_dev.dev_jkizer_staging.stg_star_payer_measure_names svh_qm
		on to_varchar(qra.data:"Measure"::string) = svh_qm.payer_measure_name
		and svh_qm.payer_name = 'Wellcare/Centene'
	where lower(data:"Measure"::string) not like '%med adherence%'
	and data:"Star Flag"::string = 'Y'
), qra_2025_1_report_date as (
	select
		src_file_name,
		max(report_date) as report_date,
		coalesce(
			try_to_timestamp_ntz(regexp_substr(src_file_name, 'MY(\\d{4})', 1, 1, 'e') || '-01-01'),
			try_to_timestamp_ntz('20' || regexp_substr(src_file_name, 'MY(\\d{2})', 1, 1, 'e') || '-01-01'),
			least_ignore_nulls(max(measure_year), date_trunc(year, max(report_date)))
		) as measure_year,
	from wellcare_quality_qra_2025_1
	group by src_file_name
), wellcare_id_lookup as (
	select
		member_id,
		wellcare_subscriber_id,
	from dw_dev.dev_jkizer_staging.stg_wellcare_enrollment
	where member_id != wellcare_subscriber_id
	group by all
)
select 
	member_id,
	to_timestamp_ntz(date_from_parts(year(report_date), '01', '01')) as measure_year,
	svh_qm.quality_measure,
	svh_qm.measure_display_name,
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
where pws.src_file_name not in ('SUVIDA HEALTHCARE Gaps and Perf Report 1.30.26.xlsx', 'SUVIDA HEALTHCARE Gaps and Perf Report 1.9.26.xlsx')

union all

select
	member_id,
	measure_year,
	quality_measure,
	measure_display_name,
	quality_measure_type,
	measure_weight,
	payer_quality_measure,
	payer_suvida_measure_match,
	measure_status,
	member_status,
	measure_detail,
	med_perc,
	thirty_to_ninety,
	max_days,
	report_date,
	source,
	src_file_name,
from wellcare_quality_qra_2024_2
where src_file_name not in ('SUVIDA HEALTHCARE Gaps and Perf Report 1.30.26.xlsx', 'SUVIDA HEALTHCARE Gaps and Perf Report 1.9.26.xlsx')

union all

select
	coalesce(wil.member_id, qra.member_id) as member_id,
	rd.measure_year,
	quality_measure,
	measure_display_name,
	quality_measure_type,
	measure_weight,
	payer_quality_measure,
	payer_suvida_measure_match,
	measure_status,
	member_status,
	measure_detail,
	med_perc,
	thirty_to_ninety,
	max_days,
	rd.report_date,
	source,
	qra.src_file_name,
from wellcare_quality_qra_2025_1 qra
inner join qra_2025_1_report_date rd
	on qra.src_file_name = rd.src_file_name
left join wellcare_id_lookup wil 
	on qra.member_id = wil.wellcare_subscriber_id
where qra.src_file_name not in ('SUVIDA HEALTHCARE Gaps and Perf Report 1.30.26.xlsx', 'SUVIDA HEALTHCARE Gaps and Perf Report 1.9.26.xlsx')