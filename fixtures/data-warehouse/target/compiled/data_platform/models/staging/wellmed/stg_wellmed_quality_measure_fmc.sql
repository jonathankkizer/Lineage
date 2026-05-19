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
		regexp_substr(lower(measure_detail), '([0-9]+) of ([0-9]+) met', 1, 1, 'c', 1)as num,
		regexp_substr(lower(measure_detail), '([0-9]+) of ([0-9]+) met', 1, 1, 'c', 2)as den,
		1 as current_duplicate
	from dw_dev.dev_jkizer_staging.stg_wellmed_quality_measure
	where quality_measure in ('Follow-Up After Emergency Department Visit for People With Multiple High-Risk Chronic Conditions (7 days)') -- event-based quality measures; measure detail has x of y met
	and lower(measure_detail) not like '%exc - %'
	and try_to_number(regexp_substr(measure_detail, '([0-9]+) of ([0-9]+) met', 1, 1, 'c', 2)) is not null
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
)
select
	member_id,
	quality_measure,
	measure_display_name,
	measure_year,
	measure_weight,
	quality_measure_type,
	source,
	measure_detail || ' Event Count: ' || current_duplicate as measure_detail,
	iff(current_duplicate > num, 0, 1) as measure_numerator, 
	iff(current_duplicate > num, 'open', 'closed') as measure_status, 
	report_date,
	src_file_name,
from duplicates