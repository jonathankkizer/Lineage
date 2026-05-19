
  
    

create or replace transient table dw_dev.dev_jkizer.int_outreach_patient
    copy grants
    
    
    as (

select
    suvida_id,
    full_name,
    location_name,
    provider_name,
    elation_patient_url,
    high_risk_patient,
    emr_claims_blended_risk_score_adj_rolling,
    emr_claims_blended_risk_score_adj_ytd,
    census_rolling_12_ip_admit,
    census_rolling_12_er_event,
    census_rolling_12_ip_readmit_30day,
    census_rolling_3_ip_admit,
    census_rolling_3_er_event,
    census_most_recent_ip_admit_date,
    census_most_recent_er_admit_date,
    payer_name,
    payer_parent,
    payer_contract,
    payer_plan_program_type,
    payer_plan_network_type,
    is_active_assignment,
    eligibility_start_month,
    eligibility_max_month,
    last_pcp_appt_date,
    next_pcp_appt_date,
    next_careteam_appt_date,
    elation_status,
    active_tag_list,
    phone,
    preferred_language,
    dual_status,
    open_quality_gaps,
    md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(full_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(high_risk_patient as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(emr_claims_blended_risk_score_adj_rolling as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(emr_claims_blended_risk_score_adj_ytd as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(census_rolling_12_ip_admit as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(census_rolling_12_er_event as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(census_rolling_12_ip_readmit_30day as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(census_rolling_3_ip_admit as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(census_rolling_3_er_event as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(census_most_recent_ip_admit_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(census_most_recent_er_admit_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(payer_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(payer_parent as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(payer_contract as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(payer_plan_program_type as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(payer_plan_network_type as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(is_active_assignment as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(eligibility_start_month as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(eligibility_max_month as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(last_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(next_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(next_careteam_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(elation_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(active_tag_list as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(phone as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(preferred_language as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(dual_status as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(open_quality_gaps as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_skey
from dw_dev.dev_jkizer.patient_summary
    )
;


  