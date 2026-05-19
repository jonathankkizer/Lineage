
  create or replace   view dw_dev.dev_jkizer_staging.stg_united_quality_measure_trc_mrp
  
  copy grants
  
  
  as (
    with recursive duplicates as (
	select 
		member_id, 
		report_date, 
		src_file_name, 
		measure_year, 
		measure_weight,
		quality_measure_type,
		source, 
		aco_flag,
		'TRC - Medication Reconciliation Post-Discharge' as quality_measure,
		max(iff(payer_quality_measure in ('DMC16-Transitions of Care - Medication Reconciliation Post Discharge - Completed MRPs .', 'DMC16-Transitions of Care - Medication Reconciliation Post Discharge - Completed MRPs '), value_num, null)) as measure_detail,
		max(iff(payer_quality_measure in ('DMC16-Transitions of Care - Medication Reconciliation Post Discharge - Completed MRPs .', 'DMC16-Transitions of Care - Medication Reconciliation Post Discharge - Completed MRPs '), value_num, null)) as num,
		max(iff(payer_quality_measure in ('DMC16-Transitions of Care – Medication Reconciliation Post-Discharge - Eligible Discharges .', 'DMC16-Transitions of Care – Medication Reconciliation Post-Discharge - Eligible Discharges '), value_num, null)) as den,
		1 as current_duplicate
	from dw_dev.dev_jkizer_staging.stg_united_quality_measure
	where payer_quality_measure in (
		'DMC16-Transitions of Care - Medication Reconciliation Post Discharge - Completed MRPs .',
		'DMC16-Transitions of Care – Medication Reconciliation Post-Discharge - Eligible Discharges .',
		'DMC16-Transitions of Care - Medication Reconciliation Post Discharge - Completed MRPs ',
		'DMC16-Transitions of Care – Medication Reconciliation Post-Discharge - Eligible Discharges '
	) -- event-based quality measures; measure detail has x of y met
	group by all
	union all
	select 
		member_id, 
		report_date, 
		src_file_name, 
		measure_year, 
		measure_weight,
		quality_measure_type,
		source, 
		aco_flag,
		quality_measure, 
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
	measure_year,
	measure_weight,
	quality_measure_type,
	source,
	aco_flag,
	measure_detail || ' Event Count: ' || current_duplicate as measure_detail,
	iff(current_duplicate > num, 0, 1) as measure_numerator, 
	iff(current_duplicate > num, 'open', 'closed') as measure_status, 
	report_date,
	src_file_name,
from duplicates
where report_date >= '2025-08-01'
  );

