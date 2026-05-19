/* DEPRECATE PENDING POWERBI RETIREMENT; patient_hcc to replace */
with patient_hccs as (
	select
		suvida_id,
		hcc_model,
		max(case when r_hcc.hcc_label = 'Vascular Disease' then 1 else 0 end) as vascular_disease_flag,
		max(case when r_hcc.hcc_label = 'Congestive Heart Failure' then 1 else 0 end) as congestive_heart_failure_flag,
		max(case when r_hcc.hcc_label = 'Major Depressive, Bipolar, and Paranoid Disorders' then 1 else 0 end) as major_dep_bip_par_flag,
		max(case when r_hcc.hcc_label = 'Coagulation Defects and Other Specified Hematological Disorders' then 1 else 0 end) as coagulation_defects_flag,
		max(case when r_hcc.hcc_label = 'Chronic Obstructive Pulmonary Disease' then 1 else 0 end) as copd_flag,
		max(case when r_hcc.hcc_label = 'Other Significant Endocrine and Metabolic Disorders' then 1 else 0 end) as endo_meta_flag,
		max(case when r_hcc.hcc_label = 'Substance Use Disorder, Moderate/Severe, or Substance Use with Complications' then 1 else 0 end) as substance_flag,
		max(case when r_hcc.hcc_label = 'Diabetes with Chronic Complications' then 1 else 0 end) as diabetes_cc_flag,
		max(case when r_hcc.hcc_label = 'Diabetes without Complication' then 1 else 0 end) as diabetes_non_cc_flag,
		max(case when r_hcc.hcc_label = 'Morbid Obesity' then 1 else 0 end) as morbid_obesity_flag,
		max(case when r_hcc.hcc_label = 'Chronic Kidney Disease, Moderate (Stage 3)' then 1 else 0 end) as ckd_3_flag,
		max(case when r_hcc.hcc_label = 'Chronic Kidney Disease, Severe (Stage 4)' then 1 else 0 end) as ckd_4_flag,
		max(case when r_hcc.hcc_label = 'Chronic Kidney Disease, Stage 5' then 1 else 0 end) as ckd_5_flag,
		max(case when r_hcc.hcc_label = 'Angina Pectoris' then 1 else 0 end) as angina_pectoris_flag,
		max(case when r_hcc.hcc_label = 'Disorders of Immunity' then 1 else 0 end) as disorders_immunity_flag
	from dw_dev.dev_jkizer.fct_patient_hcc_diagnosis hd
	left join dw_dev.dev_jkizer_staging.stg_elation_hcc_lookup r_hcc 
		on hd.hcc_code = concat('HCC', r_hcc.hcc_code)
		and r_hcc.version = 2023
	where hd.source_type = 'emr'
	and hd.period_type = 'rolling_12_month'
	and hd.is_max_monthly_period = 'FALSE'
	group by hd.suvida_id, hd.hcc_model
)
select 
	ps.*,
	'24' as model,
	coalesce(hd.vascular_disease_flag, 0) as vascular_disease_flag,
	coalesce(hd.congestive_heart_failure_flag, 0) as congestive_heart_failure_flag,
	coalesce(hd.major_dep_bip_par_flag, 0) as major_dep_bip_par_flag,
	coalesce(hd.coagulation_defects_flag, 0) as coagulation_defects_flag,
	coalesce(hd.copd_flag, 0) as copd_flag,
	coalesce(hd.endo_meta_flag, 0) as endo_meta_flag,
	coalesce(hd.substance_flag, 0) as substance_flag,
	coalesce(hd.diabetes_cc_flag, 0) as diabetes_cc_flag,
	coalesce(hd.diabetes_non_cc_flag, 0) as diabetes_non_cc_flag,
	coalesce(hd.morbid_obesity_flag, 0) as morbid_obesity_flag,
	coalesce(hd.ckd_3_flag, 0) as ckd_3_flag,
	coalesce(hd.ckd_4_flag, 0) as ckd_4_flag,
	coalesce(hd.ckd_5_flag, 0) as ckd_5_flag,
	coalesce(hd.angina_pectoris_flag, 0) as angina_pectoris_flag,
	coalesce(hd.disorders_immunity_flag, 0) as disorders_immunity_flag
from dw_dev.dev_jkizer.patient_summary ps 
left join patient_hccs hd
	on ps.suvida_id = hd.suvida_id
	and hd.hcc_model = '24'