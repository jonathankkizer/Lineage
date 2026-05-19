with recursive duplicates as (
	select 
		member_id, 
		report_date, 
		src_file_name, 
		measure_year, 
		measure_weight,
		quality_measure_type,
		source, 
		quality_measure,
		quality_measure as measure_display_name,
		measure_detail,
		coalesce(nullif(split(replace(measure_detail, '\n', ' '), ' ')[8]::varchar, '--'), 0) as num, 
		split(replace(measure_detail, '\n', ' '), ' ')[4]::decimal as den, 
		1 AS current_duplicate
	from dw_dev.dev_jkizer_staging.stg_wellmed_quality_measure
	where quality_measure in ('Plan All-Cause Readmissions') -- event-based quality measures; measure detail has x of y met
	and measure_detail not ilike '%exclusion%'
	union all
	select 
		member_id, 
		report_date, 
		src_file_name, 
		measure_year, 
		measure_weight,
		quality_measure_type,
		source, 
		quality_measure,
		measure_display_name,
		measure_detail,
		num,
		den,
		current_duplicate + 1
	from duplicates
	where current_duplicate < den
), base_data as (
select
	member_id,
	quality_measure,
	measure_display_name,
	measure_year,
	measure_weight,
	quality_measure_type,
	source,
	measure_detail || ' Event Count: ' || current_duplicate as measure_detail,
	iff(current_duplicate > num, 1, 0) as measure_numerator, 
	iff(current_duplicate > num, 'closed', 'open') as measure_status, 
	report_date,
	src_file_name,
from duplicates
)
select
	member_id,
	quality_measure,
	measure_display_name,
	measure_year,
	measure_weight,
	quality_measure_type,
	source,
	measure_detail,
	iff(measure_numerator = 1, 0, 1) as measure_numerator,
	iff(measure_status = 'open', 'closed', 'open') as measure_status, 
	report_date,
	src_file_name,
from base_data