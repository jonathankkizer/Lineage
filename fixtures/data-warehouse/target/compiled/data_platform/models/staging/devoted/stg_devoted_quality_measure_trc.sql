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
		source_numerator as num,
		source_denominator as den,
		1 as current_duplicate
	from dw_dev.dev_jkizer_staging.stg_devoted_quality_measure
	where quality_measure in ('TRC - Medication Reconciliation Post-Discharge', 'TRC - Notification of Inpatient Admission', 'TRC - Receipt of Discharge Information', 'TRC - Patient Engagement after Inpatient Discharge')
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
	'Event Count: ' || current_duplicate as measure_detail,
	iff(current_duplicate > num, 0, 1) as measure_numerator, 
	iff(current_duplicate > num, 'open', 'closed') as measure_status, 
	report_date,
	src_file_name,
from duplicates