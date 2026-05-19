
  
    

create or replace transient table dw_dev.dev_jkizer.patient_claim_inpatient
    copy grants
    
    
    as (select
	ips.*,
	ips.suvida_id || encounter_start_date as temp_encounter_type_key,
	stl.parent_organization,
	stl.address,
	stl.city,
	stl.state,
	stl.zip_code,
	stl.latitude,
	stl.longitude,
	stp.provider_first_name,
	stp.provider_last_name,
	stp.practice_affiliation,
	stp.specialty,
	stp.sub_specialty,
	w.final_post_acute_drg,
	w.final_special_pay_drg,
	w.mdc,
	w.type,
	w.ms_drg_title,
	w.drg_weight_raw,
	w.drg_weight,
	w.geometric_mean_los as drg_geometric_mean_los,
	w.arithmetic_mean_los as drg_arithmetic_mean_los,
from dw_dev.dev_jkizer_staging.stg_tuva_encounter ips
left join dw_dev.dev_jkizer_staging.stg_tuva_location stl
	on ips.facility_id = stl.location_id
left join dw_dev.dev_jkizer_staging.stg_tuva_practitioner stp 
	on ips.attending_provider_id = stp.practitioner_id
left join dw_dev.dev_jkizer_staging.stg_ms_drg_weights_los w
	on w.ms_drg  = lpad(ips.drg_code, 3, '0')
	and year(ips.encounter_start_date) = w.fiscal_year
inner join dw_dev.dev_jkizer.patient_financial_membership pfm
	on pfm.suvida_id = ips.suvida_id 
	and pfm.financial_member_month = date_trunc('month', ips.encounter_start_date)
	and financial_member_month_ind = 1
where encounter_group = 'inpatient'
    )
;


  