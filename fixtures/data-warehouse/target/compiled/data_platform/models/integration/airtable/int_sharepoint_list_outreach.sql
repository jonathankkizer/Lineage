

select
    suvida_id,
    elation_id,
    elation_patient_url,
    full_name,
    phone,
    num_pcp_visits_ytd,
    is_awv_complete_ytd,
    last_pcp_appt_date,
    preferred_language,
    location_name,
    provider_name,
    emr_claims_blended_risk_score_adj_rolling,
    outstanding_v28_community_raf,
    recent_come_back_care_note_text,
    eligibility_start_month,
    cumulative_pcp_visits,
    high_risk_patient,
    dual_status,
    priority,
    days_since_last_pcp_visit,
    category,
    date_sort,
    integration_skey
from dw_dev.dev_jkizer.int_sharepoint_list_outreach_incremental
where snapshot_date = (select max(snapshot_date) from dw_dev.dev_jkizer.int_sharepoint_list_outreach_incremental)