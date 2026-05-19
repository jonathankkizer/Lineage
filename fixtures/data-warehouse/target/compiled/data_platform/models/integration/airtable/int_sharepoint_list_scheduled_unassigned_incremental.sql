/*
  Daily snapshot of patients scheduled but not actively assigned.

  Purpose: Tracks patients who have an upcoming PCP appointment in the current
  year but are not actively assigned. Since assignment status and appointment
  details change over time, this model retains daily snapshots for historical
  reporting and sync operations.

  Behavior:
  - Uses delete+insert strategy to overwrite records for current date on each run
  - Final dbt run of the day captures the end-of-day state
  - Creates one record per suvida_id + snapshot_date combination
  - Downstream model int_sharepoint_list_scheduled_unassigned filters to latest snapshot_date only
*/



with patient_base as (
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
        is_active_assignment,
        is_pcp_visit_complete_ytd
    from dw_dev.dev_jkizer.patient_summary
),

eligible_patients as (
    select *
    from patient_base
    where is_active_assignment = 0
        and date_part('year', next_pcp_appt_date) = date_part('year', current_date())
        and last_pcp_appt_date is not null
        and is_pcp_visit_complete_ytd = 0
),

final as (
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
        current_date as snapshot_date,
        md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(next_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(last_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(high_risk_patient as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(payer_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(num_pcp_visits_ytd_group as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(cumulative_pcp_visits as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_skey
    from eligible_patients
)

select *
from final