with diagnoses as (
	select distinct
		hd.suvida_id,
		hd.hcc_model,
		hd.hcc_code,
		hb.hcc_label,
		hd.source_type,
		expected_prevalence_perc,
		first_value(hd.icd_10_code) over (partition by hd.suvida_id, hd.hcc_model, hd.hcc_code order by fd.diagnosis_date desc) as icd_10_code,
		min(fd.diagnosis_date) over (partition by hd.suvida_id, hd.hcc_model, hd.hcc_code, hd.source_type) as first_diagnosis_date,
		max(fd.diagnosis_date) over (partition by hd.suvida_id, hd.hcc_model, hd.hcc_code, hd.source_type) as recent_diagnosis_date,
		max(fd.is_risk_adjustable) over (partition by hd.suvida_id, hd.hcc_model, hd.hcc_code, hd.source_type) as is_risk_adjustable,
		max(iff(hd.source_type = 'emr_claims', fd.is_inpatient_diagnosis, null)) over (partition by hd.suvida_id, hd.hcc_model, hd.hcc_code, hd.source_type) as is_only_inpatient_diagnosis,
		max(iff(fd.source_type = 'emr', true, false)) over (partition by hd.suvida_id, hd.hcc_model, hd.hcc_code, hd.source_type) as is_emr_diagnosis,
		max(iff(fd.source_type = 'claims', true, false)) over (partition by hd.suvida_id, hd.hcc_model, hd.hcc_code, hd.source_type) as is_claims_diagnosis,
		max(iff(fd.source_type = 'emr_claims', true, false)) over (partition by hd.suvida_id, hd.hcc_model, hd.hcc_code, hd.source_type) as is_emr_claims_diagnosis,
	from dw_dev.dev_jkizer.fct_patient_hcc_diagnosis hd
	inner join dw_dev.dev_jkizer.fct_diagnosis fd 
		on hd.suvida_id = fd.suvida_id 
		and hd.icd_10_code = fd.icd_10_code
		and hd.source_type = fd.source_type
		and fd.diagnosis_date between hd.period_start_date and hd.period_end_date
	inner join dw_dev.dev_jkizer_source.hcc_benchmark hb 
		on 'HCC' || hd.hcc_code::varchar = hb.hcc_category
		and 'V' || hd.hcc_model = hb.hcc_model
	where hd.period_type = 'monthly'
	and hd.is_max_monthly_period = 1
), hcc_cats as (
	select
		hcc_model,
		hcc_label,
		hcc_code,
	from diagnoses d
	group by 1,2,3
)
select 
	ps.suvida_id,
	hc.hcc_model,
	d.hcc_code,
	hc.hcc_label,
	max(iff(is_emr_diagnosis = true, 1, 0)) as hcc_ind,
	max(iff(is_emr_claims_diagnosis = true and is_emr_diagnosis = false, 1, 0)) as hcc_claim_ind,
	max(iff(is_emr_claims_diagnosis = true, 1, 0)) as hcc_emr_claim_ind,
	min(d.first_diagnosis_date) as first_diagnosis_date,
	max(d.recent_diagnosis_date) as recent_diagnosis_date,
	d.icd_10_code,
	expected_prevalence_perc,
	booland_agg(d.is_only_inpatient_diagnosis) as is_only_inpatient_diagnosis,
	max(d.is_risk_adjustable) as is_risk_adjustable,
from dw_dev.dev_jkizer.dim_patient ps
full outer join hcc_cats hc
	on 1=1
left join diagnoses d 
	on ps.suvida_id = d.suvida_id
	and hc.hcc_model = d.hcc_model
	and hc.hcc_label = d.hcc_label
group by all