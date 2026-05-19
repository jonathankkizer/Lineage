
  
    

create or replace transient table dw_dev.dev_jkizer.fct_diagnosis
    copy grants
    
    
    as (with risk_adjustment_status as (
	select
		b.bill_id,
		bi.bill_item_id,
		max(iff(ra_cpt.hcpcs_cpt_code is not null, true, false)) as is_risk_adjustable,
	from dw_dev.dev_jkizer_staging.stg_elation_bill b
	inner join dw_dev.dev_jkizer_staging.stg_elation_visit_note vn 
		on b.visit_note_id = vn.visit_note_id
	inner join dw_dev.dev_jkizer_staging.stg_elation_bill_item bi
		on b.bill_id = bi.bill_id
	left join dw_dev.dev_jkizer_staging.stg_ref_hcc_risk_adjustable_cpt ra_cpt
		on bi.cpt_code = ra_cpt.hcpcs_cpt_code
		and year(vn.document_date) = ra_cpt.year
	group by all
), elation_diagnoses as (
	select 
		md5(cast(coalesce(cast(siw.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.visit_note_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.patient_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.document_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(vn.signed_datetime as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(u_phy.npi as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as encounter_skey,
		siw.suvida_id,
		vn.patient_id,
		dx.icd_10_code,
		dx.bill_item_diagnosis_sequence_no,
		vn.document_date as diagnosis_date,
		b.bill_id,
		bi.cpt_code,
		null as hcpcs_modifier_1,
		vn.visit_note_id,
		vn.physician_user_id,
		u_phy.user_name as provider_name,
		u_cre.user_name as diagnosis_created_user_name,
		u_phy.npi,
		'Elation' as source,
		iff(bi.created_by_user_id in (1616564, 1916540, 1406641, 1532886, 1876276), true, false) as is_coder_created,
		ras.is_risk_adjustable,
		b.deferred_bill,
	from dw_dev.dev_jkizer_staging.stg_elation_bill b
	inner join dw_dev.dev_jkizer_staging.stg_elation_visit_note vn 
		on b.visit_note_id = vn.visit_note_id
	inner join dw_dev.dev_jkizer_staging.stg_elation_user u_phy
		on vn.physician_user_id = u_phy.user_id
	inner join dw_dev.dev_jkizer_staging.stg_elation_bill_item bi
		on b.bill_id = bi.bill_id
	inner join dw_dev.dev_jkizer_staging.stg_elation_bill_item_diagnosis dx 
		on bi.bill_item_id = dx.bill_item_id
	inner join dw_dev.dev_jkizer_staging.stg_elation_user u_cre
		on bi.created_by_user_id = u_cre.user_id
	left join dw_dev.dev_jkizer.suvida_id_walk siw 
		on vn.patient_id = siw.member_id
		and siw.source = 'Elation'
	left join risk_adjustment_status ras
		on b.bill_id = ras.bill_id
		and bi.bill_item_id = ras.bill_item_id
	where vn._is_deleted_record = 0
	and bi._is_deleted_record = 0
	and dx._is_deleted_record = 0
	and b._idx = 1 
	and vn._idx = 1
	and u_phy._idx = 1
	and bi._idx = 1
	and dx._idx = 1
), claims_diagnoses as (
	select
		suvida_id,
		cc.member_id as patient_id,
		cc.hcpcs_code as cpt_code,
		cc.hcpcs_modifier_1,
		to_varchar(cc.claim_id) as bill_id,
		cc.icd_10_code,
		cc.diagnosis_date,
		cc.data_source as source,
		'claims' as source_type, -- diagnosis in claims
		is_risk_adjustable,
		is_inpatient_diagnosis,
		row_number() over (partition by suvida_id, icd_10_code, cpt_code, diagnosis_date order by diagnosis_date desc, is_risk_adjustable desc) as _rn
	from dw_dev.dev_jkizer.fct_claims_diagnosis cc
), retro_claims_diagnoses as (
	select
		suvida_id,
		rc.member_id as patient_id,
		rc.hcpcs_code as cpt_code,
		rc.hcpcs_modifier_1,
		to_varchar(rc.claim_id) as bill_id,
		rc.icd_10_code,
		rc.diagnosis_date,
		rc.data_source as source,
		'retro' as source_type, -- diagnosis in retro claims
		is_risk_adjustable,
		is_inpatient_diagnosis,
		row_number() over (partition by suvida_id, icd_10_code, cpt_code, diagnosis_date order by diagnosis_date desc, is_risk_adjustable desc) as _rn
	from dw_dev.dev_jkizer.fct_claims_diagnosis_retro rc
), emr_diagnoses as (
	select
		suvida_id,
		encounter_skey,
		to_varchar(patient_id) as patient_id,
		icd_10_code,
		bill_item_diagnosis_sequence_no,
		cpt_code,
		hcpcs_modifier_1,
		diagnosis_date,
		to_varchar(bill_id) as bill_id,
		visit_note_id,
		physician_user_id,
		provider_name,
		npi,
		source,
		'emr' as source_type, -- diagnosis in EMR,
		diagnosis_created_user_name,
		is_coder_created,
		is_risk_adjustable,
		deferred_bill,
		false as is_inpatient_diagnosis,
		row_number() over (partition by suvida_id, icd_10_code, cpt_code, diagnosis_date order by diagnosis_date desc, is_risk_adjustable desc) as _rn
	from elation_diagnoses
), emr_diagnoses_filtered as (
	select * from emr_diagnoses where _rn = 1
), claims_diagnoses_filtered as (
	select * from claims_diagnoses where _rn = 1
), retro_claims_diagnoses_filtered as (
	select * from retro_claims_diagnoses where _rn = 1
), emr_claims_diagnoses as (
	select
		coalesce(edx.suvida_id, cdx.suvida_id) as suvida_id,
		coalesce(edx.patient_id, cdx.patient_id) as patient_id,
		coalesce(edx.icd_10_code, cdx.icd_10_code) as icd_10_code,
		edx.bill_item_diagnosis_sequence_no,
		coalesce(edx.diagnosis_date, cdx.diagnosis_date) as diagnosis_date,
		coalesce(edx.bill_id, cdx.bill_id) as bill_id,
		coalesce(edx.cpt_code, cdx.cpt_code) as cpt_code,
		cdx.hcpcs_modifier_1,
		edx.encounter_skey,
		edx.visit_note_id,
		edx.physician_user_id,
		edx.provider_name,
		edx.npi,
		greatest_ignore_nulls(edx.is_risk_adjustable, cdx.is_risk_adjustable) as is_risk_adjustable,
		coalesce(edx.is_inpatient_diagnosis, cdx.is_inpatient_diagnosis) as is_inpatient_diagnosis,
		edx.deferred_bill,
		coalesce(edx.source, cdx.source) as source,
		'emr_claims' as source_type,
	from emr_diagnoses_filtered edx
	full outer join claims_diagnoses_filtered cdx
		on edx.suvida_id = cdx.suvida_id
		and edx.icd_10_code = cdx.icd_10_code
		and edx.diagnosis_date = cdx.diagnosis_date
		and edx.cpt_code = cdx.cpt_code
), emr_claims_retro_diagnoses as (
	select
		coalesce(ecdx.suvida_id, rdx.suvida_id) as suvida_id,
		coalesce(ecdx.patient_id, rdx.patient_id) as patient_id,
		coalesce(ecdx.icd_10_code, rdx.icd_10_code) as icd_10_code,
		ecdx.bill_item_diagnosis_sequence_no,
		coalesce(ecdx.diagnosis_date, rdx.diagnosis_date) as diagnosis_date,
		coalesce(ecdx.bill_id, rdx.bill_id) as bill_id,
		coalesce(ecdx.cpt_code, rdx.cpt_code) as cpt_code,
		coalesce(ecdx.hcpcs_modifier_1, rdx.hcpcs_modifier_1) as hcpcs_modifier_1,
		ecdx.encounter_skey,
		ecdx.visit_note_id,
		ecdx.physician_user_id,
		ecdx.provider_name,
		ecdx.npi,
		greatest_ignore_nulls(ecdx.is_risk_adjustable, rdx.is_risk_adjustable) as is_risk_adjustable,
		coalesce(ecdx.is_inpatient_diagnosis, rdx.is_inpatient_diagnosis) as is_inpatient_diagnosis,
		ecdx.deferred_bill,
		coalesce(ecdx.source, rdx.source) as source,
		'emr_claims_retro' as source_type,
	from emr_claims_diagnoses ecdx
	full outer join retro_claims_diagnoses_filtered rdx
		on ecdx.suvida_id = rdx.suvida_id
		and ecdx.icd_10_code = rdx.icd_10_code
		and ecdx.diagnosis_date = rdx.diagnosis_date
		and ecdx.cpt_code = rdx.cpt_code
), unioned_data as (
	select 
		suvida_id,
		encounter_skey,
		patient_id, 
		icd_10_code, 
		bill_item_diagnosis_sequence_no,
		diagnosis_date, 
		bill_id,
		cpt_code,
		hcpcs_modifier_1,
		visit_note_id,
		physician_user_id,
		provider_name,
		npi,
		source,
		source_type,
		is_coder_created,
		is_risk_adjustable,
		is_inpatient_diagnosis,
		deferred_bill,
		diagnosis_created_user_name,
	from emr_diagnoses_filtered
	union all
	select 
		suvida_id,
		null as encounter_skey,
		patient_id, 
		icd_10_code, 
		null as bill_item_diagnosis_sequence_no,
		diagnosis_date, 
		bill_id,
		cpt_code,
		hcpcs_modifier_1,
		null as visit_note_id,
		null as physician_user_id,
		null as provider_name,
		null as npi,
		source,
		source_type,
		null as is_coder_created,
		is_risk_adjustable,
		is_inpatient_diagnosis,
		null as deferred_bill,
		null as diagnosis_created_user_name,
	from claims_diagnoses_filtered
	union all
	select 
		suvida_id,
		encounter_skey,
		patient_id, 
		icd_10_code, 
		bill_item_diagnosis_sequence_no,
		diagnosis_date,
		bill_id,
		cpt_code,
		hcpcs_modifier_1,
		visit_note_id,
		physician_user_id,
		provider_name,
		npi,
		source,
		source_type,
		null as is_coder_created,
		is_risk_adjustable,
		is_inpatient_diagnosis,
		deferred_bill,
		null as diagnosis_created_user_name,
	from emr_claims_diagnoses
	union all
	select
		suvida_id,
		encounter_skey,
		patient_id,
		icd_10_code,
		bill_item_diagnosis_sequence_no,
		diagnosis_date,
		bill_id,
		cpt_code,
		hcpcs_modifier_1,
		visit_note_id,
		physician_user_id,
		provider_name,
		npi,
		source,
		source_type,
		null as is_coder_created,
		is_risk_adjustable,
		is_inpatient_diagnosis,
		deferred_bill,
		null as diagnosis_created_user_name,
	from emr_claims_retro_diagnoses
)
select
	ud.suvida_id,
	ud.encounter_skey,
	ud.patient_id, 
	ud.icd_10_code, 
	substr(icd_10_code, 1, 3) as icd_root,
	ud.bill_item_diagnosis_sequence_no,
	ud.diagnosis_date,
	ud.bill_id,
	ud.cpt_code,
	ud.hcpcs_modifier_1,
	ud.visit_note_id,
	ud.physician_user_id,
	ud.provider_name,
	ud.npi,
	ud.source,
	ud.source_type,
	ud.is_coder_created,
	ud.is_risk_adjustable,
	ud.is_inpatient_diagnosis,
	ud.deferred_bill,
	ud.diagnosis_created_user_name,
	eicd.code_description as icd_10_code_description,
	md5(cast(coalesce(cast(ud.suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(to_varchar(year(ud.diagnosis_date) + 1) as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ud.icd_10_code as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as attestation_opportunity_skey,
from unioned_data ud
left join dw_dev.dev_jkizer_staging.stg_elation_icd10 eicd
	on trim(replace(ud.icd_10_code,'.','')) = trim(REPLACE(eicd.code, '.', ''))
	and eicd._idx = 1
    )
;


  