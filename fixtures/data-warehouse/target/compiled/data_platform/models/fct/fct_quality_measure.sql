with quality_data_skeys as (
	select
		md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_year as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(quality_measure as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(src_file_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(quality_measure_occurrence_skey as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as quality_measure_report_skey,
		md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(measure_year as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(quality_measure as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(quality_measure_occurrence_skey as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as quality_measure_skey,
		quality_measure_occurrence_skey,
		suvida_id,
		iqm.member_id,
		measure_year,
		measure_display_name as quality_measure,
		quality_measure_type,
		measure_weight,
		measure_status,
		measure_numerator,
		measure_denominator,
		measure_detail,
		aco_flag,
		payer_group,
		measure_source,
		report_date,
		date_trunc(month, report_date) as report_month,
		src_file_name,
		2 as measure_source_weight, -- intmdt_quality_measure does not include svh suspect data, so this is always 2
		case
			when measure_status = 'closed' then 1
			when measure_status = 'open' then 2
		end as measure_status_weight,
	from dw_dev.dev_jkizer.intmdt_quality_measure iqm
	inner join dw_dev.dev_jkizer.suvida_id_walk siw
		on iqm.member_id = siw.member_id
		-- CODE SMELL: fix ASAP once source names are standardized upstream.
		-- quality/med adherence data labels all Wellcare members (TX and AZ) as 'Wellcare/Centene',
		-- but suvida_id_walk preserves 'Wellcare AZ' for AZ members. Normalize on the walk side so
		-- AZ patients flow through while keeping this as a hash-joinable equijoin.
		and iqm.measure_source = case when siw.source = 'Wellcare AZ' then 'Wellcare/Centene' else siw.source end
)
select
	*,
	-- latest report for each unique patient-measure-year combo (quality_measure_skey)
	dense_rank() over (partition by suvida_id, measure_year, quality_measure, quality_measure_occurrence_skey order by report_date desc, measure_source) as quality_measure_report_rank,
	-- latest report file across all patients/measures for this payer; used for is_current_report flag
	-- dense_rank() over (partition by measure_source order by report_date desc, measure_source) as report_rank,
	-- latest report for this patient across all measures
	dense_rank() over (partition by suvida_id order by report_date desc, measure_source) as patient_report_rank,
	-- latest report for this patient for this specific measure type
	dense_rank() over (partition by suvida_id, quality_measure order by report_date desc, measure_source) as patient_measure_report_rank,
	-- latest report within each calendar month per payer/measure_year; primary filter for monthly tracking
	dense_rank() over (partition by measure_source, measure_year, report_month order by report_date desc, measure_source) as quality_report_in_month_rank,
	-- latest report for each payer within each measurement year
	dense_rank() over (partition by measure_source, measure_year order by report_date desc) as measure_year_report_rank,
	-- chronological order (1 = earliest); used for is_first_measure_appearance flag
	row_number() over (partition by suvida_id, measure_year, quality_measure, quality_measure_occurrence_skey order by report_date asc) as quality_measure_rn,
	quality_measure not in (
		'Adult Immunization Status - Flu (Current Year)',
		'Adult Immunization Status - Flu (Next Year)',
		'Adult Immunization Status - Pneumo',
		'Adult Immunization Status - Zoster',
		'Advanced Directive',
		'Care for Older Adults - Pain Assessment',
		'Polypharmacy: Use of Multiple CNS-Active Medications in Older Adults',
		'Prostate Cancer Screening',
		'Annual Wellness Visit',
		'Osteoporosis Screening in Older Women'
	) as compas_flag
from quality_data_skeys