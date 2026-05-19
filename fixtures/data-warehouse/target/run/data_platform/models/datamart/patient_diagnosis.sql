
  
    

create or replace transient table dw_dev.dev_jkizer.patient_diagnosis
    copy grants
    
    
    as (--- EMR diagnosis only 
select 
	md5(cast(coalesce(cast(encounter_skey as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cpt_code as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(fd.icd_10_code as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as diagnosis_skey,
	fd.suvida_id,
	fd.cpt_code,
	fd.icd_10_code,
	fd.icd_10_code_description,
	fd.diagnosis_date,
	fd.encounter_skey,
	fd.provider_name as diagnosis_provider_name,
	fd.npi as diagnosis_provider_npi, 
	fd.is_coder_created,
	fd.is_risk_adjustable,
	fd.diagnosis_created_user_name,
	mh.mental_health_abbreviation,
	mh.mental_health_description
from dw_dev.dev_jkizer.fct_diagnosis fd
left join dw_dev.dev_jkizer_staging.stg_map_icd_mental_health_category mh
	on fd.icd_10_code = mh.icd_10_code
where fd.source_type = 'emr'
and fd.suvida_id is not null
    )
;


  