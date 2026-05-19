
  
    

create or replace transient table dw_dev.dev_jkizer.int_patient_summary_uat
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
    first_name,
    last_name,
    preferred_name,
    birth_date,
    gender,
    race,
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
    nearest_location_name,
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
    ps.patient_acquisition_type,
    coalesce(num_months_since_eligibility_acquisition, 0) as num_months_since_eligibility_acquisition,
    coalesce(open_quality_gaps, 0) as open_quality_gaps,
    coalesce(number_of_quality_gaps, 0) as num_quality_gaps,
    emr_risk_score_ytd,
    coalesce(num_hcc_diagnoses_ytd, 0) as num_hcc_diagnoses_ytd,
    coalesce(mdportals_suspect_hcc_opportunities_count, 0) as mdportals_suspect_hcc_opportunities_count,
    first_pt_appt_date,
    last_pt_appt_date,
    next_pt_appt_date,
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
    FALSE as _is_test_patient
from dw_dev.dev_jkizer.patient_summary ps
left join provider_rippling_employees prv
    on ps.provider_npi = prv.npi

union all

select
    null as suvida_id,
    to_number(pt.elation_id, 38, 0) as elation_id,
    pt.first_name,
    pt.last_name,
    null as preferred_name,
    pt.birth_date,
    pt.gender,
    pt.race,
    pt.ethnicity,
    pt.email,
    pt.phone,
    pt.preferred_language,
    pt.address_line_1,
    pt.address_line_2,
    pt.city,
    pt.state,
    pt.zip,
    FALSE as is_active_assignment,
    FALSE as is_future_assignment,
    FALSE as is_active_patient,
    patient_status as elation_status,
    null as assigned_guia_name,
    us.user_name as provider_name,
    null as provider_npi,
    us.physician_id as provider_id,
    us.user_email as provider_email,
    sl.service_location_name as location_name,
    null as nearest_location_name,
    null as payer_name,
    null as payer_plan_code,
    null as payer_plan_name,
    null as payer_member_id,
    null as elation_insurance_plan,
	null as payer_plan_program_type,
	null as payer_plan_network_program_type,
	null as payer_medicare_beneficiary_id,
	null as payer_assigned_provider_name,
    null as eligibility_start_month,
    null as eligibility_max_month,
    null as dual_status,
    null as patient_acquisition_type,
    0 as num_months_since_eligibility_acquisition,
    0 as open_quality_gaps,
    0 as num_quality_gaps,
    0 as emr_risk_score_ytd,
    0 as num_hcc_diagnoses_ytd,
    0 as mdportals_suspect_hcc_opportunities_count,
    null as first_pt_appt_date,
    null as last_pt_appt_date,
    null as next_pt_appt_date,
    null as last_pcp_appt_date,
    null as next_pcp_appt_date,
    null as last_awv_date,
    0 as high_risk_patient,
    null as active_insecurities,
    null as most_recent_height,
    null as most_recent_height_units,
    null as most_recent_height_date,
    null as most_recent_weight,
    null as most_recent_weight_units,
    null as most_recent_weight_date,
    pt._is_test_patient
from dw_dev.dev_jkizer_staging.stg_elation_patient pt
left join dw_dev.dev_jkizer_staging.stg_elation_user us
    on pt.primary_physician_user_id = us.user_id
left join dw_dev.dev_jkizer_staging.stg_elation_service_location sl
    on pt.preferred_service_location_id = sl.service_location_id
where pt._is_test_patient = TRUE
    )
;


  