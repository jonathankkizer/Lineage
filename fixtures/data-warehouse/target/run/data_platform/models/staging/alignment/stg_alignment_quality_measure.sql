
  create or replace   view dw_dev.dev_jkizer_staging.stg_alignment_quality_measure
  
  copy grants
  
  
  as (
    with base as (
	select 
		lpad(to_varchar(data:"Member ID"::int), 11, '0') as member_id,
		/* measures as columns */
		data:BCS::varchar as bcs,
		data:EED::varchar as eed,
		data:GSD::varchar as gsd,
		data:CBP::varchar as cbp,
		data:COL::varchar as col,
		data:OMW::varchar as omw,
		data:"SPC "::varchar as spc,
		data['COA ' || chr(10) || 'FSA']::string as coa_fsa,
		data['COA ' || chr(10) || 'MDR']::string as coa_mdr,
		data['COA ' || chr(10) || 'PNS']::string as coa_pns,
		data:SUPD::varchar as supd,
		data:"TRC PATIENT"::varchar as trc_patient,
		data:"TRC MRP"::varchar as trc_mrp,
		data:KED::varchar as ked,
		data:FMC::varchar as fmc,
		data:PCR::varchar as pcr,
		data:RAS::varchar as ras,
		data:Statin::varchar as statin,
		data:Diabetes::varchar as diabetes,
		/* metadata */
		to_date(data:"PCP Visit"::varchar, 'MM/DD/YYYY') as pcp_visit_date,
		replace(
		  split(_ab_source_file_url, '/')[array_size(split(_ab_source_file_url, '/'))-2]::varchar,
		  '_Gap Summary.parquet',
		  '.xlsx'
		) as src_file_name,
		to_date(

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
) as report_date,
		'Alignment AZ' as source
	from airbyte_source_prod.alignment.quality_gap_summary
	where data:"Member ID"::varchar is not null
), base_data as (
	select
		member_id,
		pcp_visit_date,
		src_file_name,
		report_date,
		source,
		quality_measure,
		quality_value
	from base
	unpivot (
		quality_value for quality_measure in (
			bcs,
			eed,
			gsd,
			cbp,
			col,
			omw,
			spc,
			coa_fsa,
			coa_mdr,
			coa_pns,
			supd,
			trc_patient,
			trc_mrp,
			ked,
			fmc,
			pcr,
			ras,
			statin,
			diabetes
		)
	)
	where quality_value is not null
), measure_year_logic as ( -- inferred measure year logic
	select
		src_file_name,
		least_ignore_nulls(
			min(year(pcp_visit_date)),
			min(year(report_date))
		) as measure_year,
	from base_data
	group by 1
)
select
	bd.member_id,
	to_timestamp_ntz(date_from_parts(myl.measure_year, '01', '01')) as measure_year,
	svh_qm.quality_measure,
	svh_qm.measure_display_name,
	svh_qm.quality_measure_type,
	svh_qm.measure_weight,
	bd.quality_measure as payer_quality_measure,
	iff(svh_qm.quality_measure is null, false, true) as payer_suvida_measure_match,
	case
		when upper(bd.quality_value) = 'Y' then 'CLOSED'
		else 'OPEN'
	end as measure_status,
	bd.quality_value as measure_detail,
	bd.pcp_visit_date,
	bd.report_date,
	bd.source,
	bd.src_file_name
from base_data bd
left join measure_year_logic myl
	on bd.src_file_name = myl.src_file_name
left join dw_dev.dev_jkizer_staging.stg_star_payer_measure_names svh_qm
	on bd.quality_measure = svh_qm.payer_measure_name
	and svh_qm.payer_name = 'Alignment AZ'
  );

