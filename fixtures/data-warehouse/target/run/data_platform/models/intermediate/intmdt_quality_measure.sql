
  
    

create or replace transient table dw_dev.dev_jkizer.intmdt_quality_measure
    copy grants
    
    
    as (with agg_gaps as ( -- combine data from staging models
	select
		member_id,
		measure_year,
		quality_measure,
		measure_display_name,
		quality_measure_type,
		measure_weight,
		measure_status,
		measure_detail,
		source as measure_source,
		report_date,
		src_file_name,
		null as aco_flag,
		null as payer_group,
	from dw_dev.dev_jkizer_staging.stg_devoted_quality_measure
	where payer_suvida_measure_match = true
	and quality_measure not in ('TRC - Medication Reconciliation Post-Discharge', 'TRC - Notification of Inpatient Admission', 'TRC - Receipt of Discharge Information', 'TRC - Patient Engagement after Inpatient Discharge') -- non-TRC Devoted quality data

	union all

	select
		member_id,
		measure_year,
		quality_measure,
		measure_display_name,
		quality_measure_type,
		measure_weight,
		measure_status,
		measure_detail,
		source as measure_source,
		report_date,
		src_file_name,
		null as aco_flag,
		null as payer_group,
	from dw_dev.dev_jkizer_staging.stg_devoted_quality_measure_trc

	union all

	select
		member_id,
		measure_year,
		quality_measure,
		measure_display_name,
		quality_measure_type,
		measure_weight,
		measure_status,
		measure_detail,
		source as measure_source,
		report_date,
		src_file_name,
		null as aco_flag,
		null as payer_group,
	from dw_dev.dev_jkizer_staging.stg_wellcare_quality_measure
	where payer_suvida_measure_match = true

	union all

	select
		member_id,
		measure_year,
		quality_measure,
		measure_display_name,
		quality_measure_type,
		measure_weight,
		measure_status,
		measure_detail,
		source as measure_source,
		report_date,
		src_file_name,
		null as aco_flag,
		null as payer_group,
	from dw_dev.dev_jkizer_staging.stg_wellmed_quality_measure
	where payer_suvida_measure_match = true
	and quality_measure not in ('TRC - Medication Reconciliation Post-Discharge', 'TRC - Notification of Inpatient Admission', 'TRC - Receipt of Discharge Information', 'TRC - Patient Engagement after Inpatient Discharge', 'TRC - Patient Engagement within 7 Days after Inpatient Discharge', 'Plan All-Cause Readmissions', 'Follow-Up After Emergency Department Visit for People With Multiple High-Risk Chronic Conditions (7 days)') -- non-TRC, non-PCR wellmed quality data
	and measure_denominator = 1

	union all

	select
		member_id,
		measure_year,
		quality_measure,
		measure_display_name,
		quality_measure_type,
		measure_weight,
		measure_status,
		measure_detail,
		source as measure_source,
		report_date,
		src_file_name,
		null as aco_flag,
		null as payer_group,
	from dw_dev.dev_jkizer_staging.stg_wellmed_quality_measure_fmc

	union all

	select
		member_id,
		measure_year,
		quality_measure,
		measure_display_name,
		quality_measure_type,
		measure_weight,
		measure_status,
		measure_detail,
		source as measure_source,
		report_date,
		src_file_name,
		null as aco_flag,
		null as payer_group,
	from dw_dev.dev_jkizer_staging.stg_wellmed_quality_measure_trc

	union all

	select
		member_id,
		measure_year,
		quality_measure,
		measure_display_name,
		quality_measure_type,
		measure_weight,
		measure_status,
		measure_detail,
		source as measure_source,
		report_date,
		src_file_name,
		null as aco_flag,
		null as payer_group,
	from dw_dev.dev_jkizer_staging.stg_wellmed_quality_measure_pcr

	union all

	select
		member_id,
		measure_year,
		quality_measure,
		measure_display_name,
		quality_measure_type,
		measure_weight,
		measure_status,
		measure_detail,
		source as measure_source,
		report_date,
		src_file_name,
		aco_flag,
		case
			when src_file_name ilike '%dsnp%' and aco_flag = 'ACO' then 'DSNP'
			when src_file_name ilike '%phoenix%' and aco_flag = 'ACO' then 'ACO-PHX'
			when src_file_name ilike '%tucson%' and aco_flag = 'ACO' then 'ACO-TUC'
			else null
		end as payer_group,
	from dw_dev.dev_jkizer_staging.stg_united_az_quality_measure
	where payer_suvida_measure_match = true
	and quality_measure not in ('TRC - Medication Reconciliation Post-Discharge', 'TRC - Notification of Inpatient Admission', 'TRC - Receipt of Discharge Information', 'TRC - Patient Engagement after Inpatient Discharge', 'TRC - Patient Engagement within 7 Days after Inpatient Discharge', 'Plan All-Cause Readmissions', 'Follow-Up After Emergency Department Visit for People With Multiple High-Risk Chronic Conditions (7 days)') -- non-TRC, non-PCR wellmed quality data
	
	union all
	
	select
		member_id,
		measure_year,
		quality_measure,
		measure_display_name,
		quality_measure_type,
		measure_weight,
		measure_status,
		measure_detail,
		source as measure_source,
		report_date,
		src_file_name,
		aco_flag,
		case
			when src_file_name ilike '%dsnp%' and aco_flag = 'ACO' then 'DSNP'
			when src_file_name ilike '%phoenix%' and aco_flag = 'ACO' then 'ACO-PHX'
			when src_file_name ilike '%tucson%' and aco_flag = 'ACO' then 'ACO-TUC'
			else null
		end as payer_group,
	from dw_dev.dev_jkizer_staging.stg_united_az_quality_measure_fmc
	
	union all 
	
	select
		member_id,
		measure_year,
		quality_measure,
		measure_display_name,
		quality_measure_type,
		measure_weight,
		measure_status,
		measure_detail,
		source as measure_source,
		report_date,
		src_file_name,
		aco_flag,
		case
			when src_file_name ilike '%dsnp%' and aco_flag = 'ACO' then 'DSNP'
			when src_file_name ilike '%phoenix%' and aco_flag = 'ACO' then 'ACO-PHX'
			when src_file_name ilike '%tucson%' and aco_flag = 'ACO' then 'ACO-TUC'
			else null
		end as payer_group,
	from dw_dev.dev_jkizer_staging.stg_united_az_quality_measure_trc_mrp
	
	union all 
	
	select
		member_id,
		measure_year,
		quality_measure,
		measure_display_name,
		quality_measure_type,
		measure_weight,
		measure_status,
		measure_detail,
		source as measure_source,
		report_date,
		src_file_name,
		aco_flag,
		case
			when src_file_name ilike '%dsnp%' and aco_flag = 'ACO' then 'DSNP'
			when src_file_name ilike '%phoenix%' and aco_flag = 'ACO' then 'ACO-PHX'
			when src_file_name ilike '%tucson%' and aco_flag = 'ACO' then 'ACO-TUC'
			else null
		end as payer_group,
	from dw_dev.dev_jkizer_staging.stg_united_az_quality_measure_trc_pe

	union all

	select
		member_id,
		measure_year,
		quality_measure,
		measure_display_name,
		quality_measure_type,
		measure_weight,
		measure_status,
		measure_detail,
		source as measure_source,
		report_date,
		src_file_name,
		null as aco_flag,
		null as payer_group,
	from dw_dev.dev_jkizer_staging.stg_alignment_quality_measure
	where payer_suvida_measure_match = true
)
select distinct -- FIX; underlying data has some duplication
    member_id,
	measure_year,
	quality_measure,
	measure_display_name,
	measure_weight,
	quality_measure_type,
	lower(measure_status) as measure_status,
	iff(lower(measure_status) = 'open', 0, 1) as measure_numerator,
	1 as measure_denominator,
	measure_detail,
	aco_flag,
	payer_group,
	measure_source,
	report_date,
	src_file_name,
	iff(quality_measure in ('Prescription 30 to 90 days opportunity','Plan All-Cause Readmissions','Follow-Up After Emergency Department Visit for People With Multiple High-Risk Chronic Conditions (7 days)','TRC - Medication Reconciliation Post-Discharge','TRC - Patient Engagement after Inpatient Discharge','TRC - Receipt of Discharge Information','TRC - Notification of Inpatient Admission', 'TRC - Patient Engagement within 7 Days after Inpatient Discharge'),
		md5(cast(coalesce(cast(measure_year as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(quality_measure as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_detail as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_numerator as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)),
		null)
	as quality_measure_occurrence_skey,
from agg_gaps as gaps
where quality_measure != 'Prescription 30 to 90 days opportunity'
    )
;


  