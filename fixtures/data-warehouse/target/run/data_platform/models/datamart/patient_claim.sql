
  
    

create or replace transient table dw_dev.dev_jkizer.patient_claim
    copy grants
    
    
    as (-- bring in location name here
select
	mc.*,
	mc.suvida_id || mc.claim_start_date as temp_encounter_type_key,
	pm.location_name,
	iff(date_trunc('month', mc.claim_start_date) between dateadd(month, -15, date_trunc(month, current_date())) and dateadd(month, -3, date_trunc(month, current_date())), true, false) as is_claim_rolling_12_window,
	npp.primary_taxonomy_code as rendering_provider_taxonomy_code,
	npp.primary_specialty_description as rendering_provider_specialty_description,
	npp.provider_organization_name as rendering_provider_organization_name,
	npp.practice_city as rendering_provider_city,
	npp.practice_state as rendering_provider_state,
	npp.practice_zip_code as rendering_provider_zip_code,
	p.specialty as rendering_provider_specialty,
	p.sub_specialty as rendering_provider_sub_specialty,
	imc.src_file_name
from dw_dev.dev_jkizer_staging.stg_medical_claim mc
left join dw_dev.dev_jkizer_staging.stg_tuva_practitioner p
	on mc.rendering_id = p.practitioner_id
left join dw_dev.dev_jkizer_staging.stg_nppes_provider npp
	on p.npi = npp.npi
left join dw_dev.dev_jkizer.intmdt_medical_claim imc
	on mc.claim_id = imc.claim_id
	and mc.claim_line_number = imc.claim_line_number
left join dw_dev.dev_jkizer.patient_care_assignment pm
	on mc.suvida_id = pm.suvida_id
	and date_trunc('month', mc.claim_start_date) = pm.care_assignment_month 
left join dw_dev.dev_jkizer.patient_financial_membership pfm
	on pfm.suvida_id = mc.suvida_id 
	and pfm.financial_member_month = date_trunc('month', mc.claim_start_date)
	and pfm.financial_member_month_ind = 1
left join dw_dev.dev_jkizer.patient_financial_membership pfm_memb_id
	on pfm_memb_id.member_id = mc.member_id
	and pfm.suvida_id is null
	and pfm_memb_id.financial_member_month = date_trunc('month', mc.claim_start_date)
	and pfm_memb_id.financial_member_month_ind = 1
where (pfm.suvida_id is not null or pfm_memb_id.member_id is not null)
group by all
    )
;


  