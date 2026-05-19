with icd_desc as (
	select distinct
		icd_10_code,
		description as icd_description
	from dw_dev.dev_jkizer_staging.stg_ref_hcc_v24_icd10 r 
), max_period as (
	select
		max(period_end_date) as max_period_end_date
	from dw_dev.dev_jkizer_staging.stg_hcc_score
	where period_type = 'monthly'
	group by all
)
select
	hd.hcc_period_patient_skey,
	hd.suvida_id,
	hd.period_start_date,
	hd.period_end_date,
	hd.run_datetime,
	hd.period_type,
	hd.source_type,
	hd.hcc_model,
	hd.icd_10_code,
	r.icd_description,
	hd.hcc_code,
	shr.hcc_description,
	iff(hd.period_type = 'monthly' and mp.max_period_end_date is not null, true, false) as is_max_monthly_period,
from dw_dev.dev_jkizer_staging.stg_hcc_icd_diagnosis hd
left join dw_dev.dev_jkizer_staging.stg_hcc_reference shr 
	on hd.hcc_model = shr.hcc_version
	and hd.hcc_code = regexp_substr(shr.hcc, '\\d+')
left join icd_desc r
	on hd.icd_10_code = r.icd_10_code
left join max_period mp 
	on hd.period_end_date = mp.max_period_end_date