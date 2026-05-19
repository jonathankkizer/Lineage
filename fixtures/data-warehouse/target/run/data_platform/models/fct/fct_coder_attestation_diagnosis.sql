
  
    

create or replace transient table dw_dev.dev_jkizer.fct_coder_attestation_diagnosis
    copy grants
    
    
    as (with icds as (
	select
		u.elation_id,
		u.assigned_coder,
		u.appointment_skey,
		u.created_datetime,
		u.last_modified_datetime,
		u.run_datetime,
		replace(u.suspect_position, 'SUSPECT_ICD_', '') as suspect_position,
		u.icd_10_code,
	from dw_dev.dev_jkizer_staging.stg_airtable_coding_pre_visit_review pv
	unpivot (icd_10_code for suspect_position in ("suspect_icd_1", "suspect_icd_2", "suspect_icd_3", "suspect_icd_4", "suspect_icd_5", "suspect_icd_6", "suspect_icd_7", "suspect_icd_8", "suspect_icd_9", "suspect_icd_10", "suspect_icd_11", "suspect_icd_12", "suspect_icd_13", "suspect_icd_14", "suspect_icd_15")) u
), icd_evidence as (
	select
		u.elation_id,
		u.appointment_skey,
		u.created_datetime,
		u.last_modified_datetime,
		u.run_datetime,
		replace(u.suspect_position, 'SUSPECT_EVIDENCE_ICD_', '') as suspect_position,
		u.icd_10_code_evidence,
	from dw_dev.dev_jkizer_staging.stg_airtable_coding_pre_visit_review pv
	unpivot (icd_10_code_evidence for suspect_position in ("suspect_evidence_icd_1", "suspect_evidence_icd_2", "suspect_evidence_icd_3", "suspect_evidence_icd_4", "suspect_evidence_icd_5", "suspect_evidence_icd_6", "suspect_evidence_icd_7", "suspect_evidence_icd_8", "suspect_evidence_icd_9", "suspect_evidence_icd_10", "suspect_evidence_icd_11", "suspect_evidence_icd_12", "suspect_evidence_icd_13", "suspect_evidence_icd_14", "suspect_evidence_icd_15")) u
)
select
	md5(cast(coalesce(cast(siw.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(to_varchar(year(ic.last_modified_datetime)) as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ic.icd_10_code as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as attestation_opportunity_skey,
	year(ic.last_modified_datetime) as measure_year,
	siw.suvida_id,
	ic.elation_id,
	ic.appointment_skey,
	ic.assigned_coder,
	ic.created_datetime,
	ic.last_modified_datetime,
	ic.suspect_position,
	ic.icd_10_code,
	ie.icd_10_code_evidence,
	row_number() over (partition by siw.suvida_id, year(ic.last_modified_datetime), ic.icd_10_code order by ic.last_modified_datetime) as coder_attestation_opportunity_index
from icds ic
left join icd_evidence ie
	on ic.appointment_skey = ie.appointment_skey
	and ic.suspect_position = ie.suspect_position
left join dw_dev.dev_jkizer.suvida_id_walk siw
	on ic.elation_id = siw.member_id
	and siw.source = 'Elation'
    )
;


  