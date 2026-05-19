
  
    

create or replace transient table dw_dev.dev_jkizer.int_patient_summary
    copy grants
    
    
    as (with provider_rippling_employees as (
    select distinct
        dp.physician_id,
        dp.npi,
        coalesce(drs.work_email, dp.user_email) as email
    from dw_dev.dev_jkizer.dim_provider dp
    left join dw_dev.dev_jkizer.dim_rippling_staff drs
        on dp.npi = drs.npi_number
)

select distinct
    suvida_id,
    to_number(elation_id, 38, 0) as elation_id,
    sf_account_id,
    first_name,
    last_name,
    full_name,
    preferred_name,
    birth_date,
    gender,
    race,
    secondary_race,
    ethnicity,
    ps.email,
    phone,
    preferred_language,
    address_line_1,
    address_line_2,
    city,
    state,
    zip,
    to_boolean(is_active_assignment) as is_active_assignment,
    is_future_assignment,
    iff(is_active_patient = 1, TRUE, FALSE) as is_active_patient,
    elation_status,
    ps.assigned_guia_name,
    ps.provider_name,
    provider_npi,
    prv.physician_id as provider_id,
    prv.email as provider_email,
    ps.location_name,
    l.location_id,
    nearest_location_name,
    nearest_location_distance,
    payer_name,
    payer_plan_code,
    payer_plan_name,
    payer_member_id,
    elation_insurance_plan,
	payer_plan_program_type,
	payer_plan_network_program_type,
	payer_medicare_beneficiary_id,
	payer_assigned_provider_name,
    eligibility_start_month,
    eligibility_max_month,
    dual_status,
    elation_patient_url,
    ps.patient_acquisition_type,
    ps.recent_non_visit_note_text,
    coalesce(num_months_since_eligibility_acquisition, 0) as num_months_since_eligibility_acquisition,
    coalesce(open_quality_gaps, 0) as open_quality_gaps,
    coalesce(number_of_quality_gaps, 0) as num_quality_gaps,
    emr_risk_score_ytd,
    emr_claims_blended_risk_score_adj_ytd,
    coalesce(num_hcc_diagnoses_ytd, 0) as num_hcc_diagnoses_ytd,
    coalesce(mdportals_suspect_hcc_opportunities_count, 0) as mdportals_suspect_hcc_opportunities_count,
    first_pt_appt_date,
    last_pt_appt_date,
    next_pt_appt_date,
    first_pcp_appt_date,
    last_pcp_appt_date,
    next_pcp_appt_date,
    last_awv_date,
    high_risk_patient,
    active_insecurities,
    most_recent_height,
    most_recent_height_units,
    most_recent_height_date,
    most_recent_weight,
    most_recent_weight_units,
    most_recent_weight_date,
    ps.creation_date,
    ps.come_back_to_care_priority
from dw_dev.dev_jkizer.patient_summary ps
left join dw_dev.dev_jkizer.dim_location l
    on ps.location_name = l.location_name
left join provider_rippling_employees prv
    on ps.provider_npi = prv.npi
    )
;


  