
  
    

create or replace transient table dw_dev.dev_jkizer.patient_hcc_process
    copy grants
    
    
    as (with payer_reports as (
	select
		cm.suvida_id,
		cm.measure_year,
		replace(cm.hcc_category, 'HCC', '') as hcc_category,
		cm.hcc_description,
		cm.hcc_version,
		'coding_report' as identification_source,
		min(report_date) as first_identification_date,
		min(iff(measure_status = 'open', report_date, null)) as open_date,
		least_ignore_nulls(min(iff(measure_status = 'closed', report_date, null)), min(fd.diagnosis_date)) as closed_date,
		max(fd.is_risk_adjustable) as is_risk_adjustable,
		listagg(distinct cm.icd_10_code, ' | ') as icd_10_code,
	from dw_dev.dev_jkizer.fct_coding_measure cm
	left join dw_dev.dev_jkizer.fct_patient_hcc_diagnosis hd
		on cm.suvida_id = hd.suvida_id
		and cm.hcc_category = hd.hcc_code
		and cm.measure_year = year(hd.period_start_date)
		and hd.period_type = 'monthly'
		and cm.hcc_version = hd.hcc_model
	left join dw_dev.dev_jkizer.fct_diagnosis fd
		on hd.suvida_id = fd.suvida_id
		and hd.source_type = fd.source_type
		and year(hd.period_start_date) = year(fd.diagnosis_date)
		and hd.icd_10_code = fd.icd_10_code
	where cm.suvida_id is not null
	and cm.is_acute_icd = false
	and cm.measure_source_year_index = 1
	group by all
), recapture as (
	select --- get all prior year HCCs that apply towards the next year
		hd.suvida_id,
		to_varchar(year(hd.period_start_date) + 1) as measure_year,
		cast(hd.hcc_code as string) as hcc_category,
		hd.hcc_description,
		hd.hcc_model as hcc_version,
		'internal_recapture' as identification_source,
		min(dateadd(year, 1, hd.period_start_date)) as first_identification_date,
		min(dateadd(year, 1, hd.period_start_date)) as open_date,
		min(fd.diagnosis_date) as closed_date,
		max(fd.is_risk_adjustable) as is_risk_adjustable,
		listagg(distinct hd.icd_10_code, ' | ') as icd_10_code,
	from dw_dev.dev_jkizer.fct_patient_hcc_diagnosis hd
	left join dw_dev.dev_jkizer.fct_patient_hcc_diagnosis hd_next_year
		on hd.suvida_id = hd_next_year.suvida_id
		and hd.source_type = hd_next_year.source_type
		and hd.period_type = hd_next_year.period_type
		and year(hd.period_start_date) + 1 = year(hd_next_year.period_start_date)
		and month(hd.period_start_date) = month(hd_next_year.period_start_date)
		and hd.hcc_code = hd_next_year.hcc_code
	left join dw_dev.dev_jkizer.fct_diagnosis fd
		on hd_next_year.suvida_id = fd.suvida_id
		and hd_next_year.source_type = fd.source_type
		and year(hd_next_year.period_start_date) = year(fd.diagnosis_date)
		and hd_next_year.icd_10_code = fd.icd_10_code
	left join dw_dev.dev_jkizer_source.map_acute_icd_10_code aicd
		on hd.icd_10_code = aicd.icd_10_code
	where datediff(month, hd.period_end_date, hd.period_start_date) = -11
	and hd.period_type = 'monthly'
	and hd.source_type = 'emr'
	and hd.suvida_id is not null
	and aicd.icd_10_code is null
	group by all
), combined_input as (
	select
		coalesce(pr.suvida_id, r.suvida_id) as suvida_id,
		coalesce(pr.measure_year, r.measure_year) as measure_year,
		coalesce(pr.hcc_category, r.hcc_category) as hcc_category,
		coalesce(pr.hcc_description, r.hcc_description) as hcc_description,
		coalesce(pr.hcc_version, r.hcc_version) as hcc_version,
		case
			when pr.suvida_id is not null and r.suvida_id is null then 'payer_only'
			when pr.suvida_id is not null and r.suvida_id is not null then 'payer_and_internal_recapture'
			when pr.suvida_id is null and r.suvida_id is not null then 'internal_recapture'
		end as hcc_opportunity_type,
		pr.open_date as payer_report_open_date,
		pr.closed_date as payer_report_closed_date,
		r.open_date as internal_recapture_open_date,
		r.closed_date as internal_recapture_closed_date,
		pr.icd_10_code as payer_icd_10_code,
		r.icd_10_code as internal_icd_10_code,
		greatest_ignore_nulls(r.is_risk_adjustable, pr.is_risk_adjustable) as internal_risk_adjustable_status,
		least_ignore_nulls(pr.open_date, r.open_date) as first_open_date,
		least_ignore_nulls(pr.closed_date, r.closed_date) as first_closed_date,
	from payer_reports pr
	full outer join recapture r
		on pr.suvida_id = r.suvida_id
		and pr.measure_year = r.measure_year
		and pr.hcc_category = r.hcc_category
		and pr.hcc_version = r.hcc_version
)
select
	md5(cast(coalesce(cast(ci.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ci.hcc_category as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ci.hcc_version as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ci.measure_year as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as patient_hcc_skey,
	ci.*,
	case
		when first_closed_date is null and internal_risk_adjustable_status is null then 'recapture_needed'
		when first_closed_date is not null and internal_risk_adjustable_status = False then 'risk_adjustable_recapture_needed'
		when first_closed_date is not null and (internal_risk_adjustable_status = True or internal_risk_adjustable_status is null) then 'recapture_complete'
	end as hcc_recapture_status,
	nullif(greatest_ignore_nulls(datediff(day, first_open_date, first_closed_date), 0), 0) as num_days_open_to_close,
	iff(first_closed_date is null, 'open', 'closed') as measure_status,
	iff(first_closed_date is null, false, true) as is_measure_closed,
from combined_input ci
    )
;


  