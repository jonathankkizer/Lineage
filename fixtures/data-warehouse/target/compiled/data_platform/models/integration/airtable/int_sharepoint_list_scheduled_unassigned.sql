

select
    suvida_id,
    full_name,
    first_name,
    last_name,
    birth_date,
    elation_patient_url,
    location_name,
    payer_name,
    elation_insurance_name,
    elation_insurance_plan,
    elation_insurance_member_id,
    eligibility_start_month,
    last_pcp_appt_date,
    next_pcp_appt_date,
    cumulative_pcp_visits,
    num_pcp_visits_ytd_group,
    high_risk_patient,
    integration_skey
from dw_dev.dev_jkizer.int_sharepoint_list_scheduled_unassigned_incremental
where snapshot_date = (select max(snapshot_date) from dw_dev.dev_jkizer.int_sharepoint_list_scheduled_unassigned_incremental)