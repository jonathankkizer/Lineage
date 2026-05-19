/*
  Daily snapshot of outreach cohort membership. One row per (suvida_id, cohort_key, snapshot_date).

  Purpose: source of truth for which patients belong to which outreach cohort each day.
  Drives episode open/close logic in int_outreach_episode and historical retention for analytics.

  Behavior:
  - delete+insert on snapshot_date — re-running the same day overwrites that day's rows
  - All prior snapshot_dates are retained indefinitely

  Cohorts implemented:
  - come_back_to_care (CBTC): active assignment, established (has last PCP appt), no future PCP appt,
      last PCP appt > 90 days ago (normal) or > 30 days ago (high-risk).
*/



with patient_base as (
    select
        suvida_id,
        is_active_assignment,
        elation_status,
        active_tag_list,
        last_pcp_appt_date,
        next_pcp_appt_date,
        high_risk_patient,
        location_name,
        provider_name
    from dw_dev.dev_jkizer.patient_summary
),

come_back_to_care as (
    select
        suvida_id,
        'come_back_to_care' as cohort_key,
        last_pcp_appt_date,
        next_pcp_appt_date,
        high_risk_patient,
        location_name,
        provider_name,
        current_date - last_pcp_appt_date as days_since_last_pcp_visit
    from patient_base
    where is_active_assignment = 1
        and (elation_status != 'deceased' or elation_status is null)
        and not lower(active_tag_list) like lower('%**HOSPICE**%')
        and next_pcp_appt_date is null
        and last_pcp_appt_date is not null
        and last_pcp_appt_date < case
                when high_risk_patient = 1 then dateadd(day, -30, current_date)
                else dateadd(day, -90, current_date)
            end
),

all_cohorts as (
    select * from come_back_to_care
),

final as (
    select
        suvida_id,
        cohort_key,
        current_date as snapshot_date,
        last_pcp_appt_date,
        next_pcp_appt_date,
        high_risk_patient,
        days_since_last_pcp_visit,
        location_name,
        provider_name
    from all_cohorts
)

select * from final