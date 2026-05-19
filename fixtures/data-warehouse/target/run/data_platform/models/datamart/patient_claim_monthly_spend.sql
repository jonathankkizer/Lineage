
  
    

create or replace transient table dw_dev.dev_jkizer.patient_claim_monthly_spend
    copy grants
    
    
    as (with inst_prof_amount as (
	select 
		suvida_id,
		data_source,
		date_trunc(month, claim_start_date) as date_month,
		sum(iff(claim_type = 'institutional', paid_amount, 0)) as institutional_paid,
		sum(iff(claim_type = 'professional', paid_amount, 0)) as professional_paid,
		sum(iff(suvida_claim_flag = false, paid_amount, 0)) as non_suvida_total_paid,
		sum(iff(claim_type = 'institutional' and suvida_claim_flag = false, paid_amount, 0)) as non_suvida_institutional_paid,
		sum(iff(claim_type = 'professional' and suvida_claim_flag = false, paid_amount, 0)) as non_suvida_professional_paid,
	from dw_dev.dev_jkizer_staging.stg_medical_claim
	group by 1,2,3
)
select
	spp.suvida_id,
	spp.date_month,
	payer,
	plan,
	spp.data_source,
	institutional_paid,
	professional_paid,
	non_suvida_institutional_paid,
	non_suvida_professional_paid,
	/*
	payer_attributed_provider,
	payer_attributed_provider_practice,
	payer_attributed_provider_organization,
	payer_attributed_provider_lob,
	custom_attributed_provider,
	custom_attributed_provider_practice,
	custom_attributed_provider_organization,
	custom_attributed_provider_lob,
	*/
	inpatient_paid,
	outpatient_paid,
	office_based_paid,
	ancillary_paid,
	other_paid,
	pharmacy_paid,
	acute_inpatient_paid,
	ambulance_paid,
	ambulatory_surgery_center_paid,
	dialysis_paid,
	durable_medical_equipment_paid,
	emergency_department_paid,
	home_health_paid,
	inpatient_hospice_paid,
	inpatient_psychiatric_paid,
	inpatient_rehabilitation_paid,
	lab_paid,
	observation_paid,
	office_based_other_paid,
	office_based_pt_ot_st_paid,
	office_based_radiology_paid,
	office_based_surgery_paid,
	office_based_visit_paid,
	other_paid_2,
	outpatient_hospice_paid,
	outpatient_hospital_or_clinic_paid,
	outpatient_pt_ot_st_paid,
	outpatient_psychiatric_paid,
	outpatient_radiology_paid,
	outpatient_rehabilitation_paid,
	outpatient_surgery_paid,
	pharmacy_paid_2,
	skilled_nursing_paid,
	telehealth_visit_paid,
	urgent_care_paid,
	inpatient_allowed,
	outpatient_allowed,
	office_based_allowed,
	ancillary_allowed,
	other_allowed,
	pharmacy_allowed,
	acute_inpatient_allowed,
	ambulance_allowed,
	ambulatory_surgery_center_allowed,
	dialysis_allowed,
	durable_medical_equipment_allowed,
	emergency_department_allowed,
	home_health_allowed,
	inpatient_hospice_allowed,
	inpatient_psychiatric_allowed,
	inpatient_rehabilitation_allowed,
	lab_allowed,
	observation_allowed,
	office_based_other_allowed,
	office_based_pt_ot_st_allowed,
	office_based_radiology_allowed,
	office_based_surgery_allowed,
	office_based_visit_allowed,
	other_allowed_2,
	outpatient_hospice_allowed,
	outpatient_hospital_or_clinic_allowed,
	outpatient_pt_ot_st_allowed,
	outpatient_psychiatric_allowed,
	outpatient_radiology_allowed,
	outpatient_rehabilitation_allowed,
	outpatient_surgery_allowed,
	pharmacy_allowed_2,
	skilled_nursing_allowed,
	telehealth_visit_allowed,
	urgent_care_allowed,
	non_suvida_total_paid,
	total_paid,
	medical_paid,
	total_allowed,
	medical_allowed,
	tuva_last_run,
	iff(inpatient_paid > 50000, true, false) as high_cost_claimant_month,
	iff(date_trunc('month', spp.date_month) between dateadd(month, -15, date_trunc(month, current_date())) and dateadd(month, -3, date_trunc(month, current_date())), true, false) as is_claim_rolling_12_window,
from dw_dev.dev_jkizer_staging.stg_pmpm_prep spp
left join inst_prof_amount ipa 
	on spp.suvida_id = ipa.suvida_id
	and spp.date_month = ipa.date_month
	and spp.data_source = ipa.data_source
inner join dw_dev.dev_jkizer.patient_financial_membership pfm
	on pfm.suvida_id = spp.suvida_id 
	and pfm.financial_member_month = date_trunc('month', spp.date_month)
	and financial_member_month_ind = 1
    )
;


  