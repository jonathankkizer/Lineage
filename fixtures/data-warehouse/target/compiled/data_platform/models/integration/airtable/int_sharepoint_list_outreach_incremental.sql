/*
  Daily snapshot of the sharepoint outreach list for historical reporting.

  Purpose: Preserves daily snapshots of patients on the outreach list. Since patients
  fall off int_sharepoint_list_outreach once scheduled/contacted, this model retains
  historical data for reporting on outreach efforts over time.

  Behavior:
  - Uses delete+insert strategy to overwrite records for current date on each run
  - Final dbt run of the day captures the end-of-day state
  - Creates one record per suvida_id + snapshot_date combination
  - Downstream model int_sharepoint_list_outreach filters to latest snapshot_date only
*/



with patient_base as (
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
        emr_claims_blended_risk_score_adj_ytd,
        emr_claims_blended_risk_score_adj_rolling,
        outstanding_v28_community_raf,
        recent_come_back_care_note_text,
        eligibility_start_month,
        cumulative_pcp_visits,
        high_risk_patient,
        dual_status,
        payer_plan_program_type,
        next_pcp_appt_date,
        is_active_assignment,
        elation_status,
        active_tag_list
    from dw_dev.dev_jkizer.patient_summary
),

eligible_patients as (
    select *
    from patient_base
    where is_active_assignment = 1
        and (elation_status != 'deceased' or elation_status is null)
        and not lower(active_tag_list) like lower('%**HOSPICE**%')
        and next_pcp_appt_date is null
        and (
            -- Patients with visit between current date and 9 months ago (excluding last 2 weeks)
            (
                last_pcp_appt_date between dateadd(month, -9, current_date()) and current_date()
                and not (last_pcp_appt_date between dateadd(week, -2, current_date) and current_date())
            )
            -- OR patients who are newer members without recent visits
            or (
                (eligibility_start_month < dateadd(day, -30, current_date) or eligibility_start_month is null)
                and (last_pcp_appt_date < dateadd(year, -1, current_date()) or last_pcp_appt_date is null)
            )
        )
),

patient_priority as (
    select
        *,
        case
            when high_risk_patient = 1 then '1 - HIGH-RISK'
            when emr_claims_blended_risk_score_adj_rolling > 1.5
                or dual_status = 'Dual'
                or emr_claims_blended_risk_score_adj_rolling - emr_claims_blended_risk_score_adj_ytd >= 0.5
                then '2 - COMPLEX'
            when cumulative_pcp_visits between 1 and 3 then '3 - LOW TOTAL VISITS'
            else '4 - ALL OTHERS'
        end as priority,
        current_date - last_pcp_appt_date as days_since_last_pcp_visit
    from eligible_patients
),

patient_category as (
    select
        *,
        case
            when last_pcp_appt_date is null then 'UNESTABLISHED'
            when last_pcp_appt_date >= dateadd(month, -9, current_date()) then 'COME BACK TO CARE'
            else 'UNENGAGED'
        end as category
    from patient_priority
),

final as (
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
        payer_plan_program_type,
        priority,
        days_since_last_pcp_visit,
        category,
        case
            when category = 'COME BACK TO CARE' then to_date('2100-01-01')
            when category in ('UNESTABLISHED', 'UNENGAGED')
                then coalesce(date_trunc('month', eligibility_start_month), to_date('1900-01-01'))
            else to_date('1900-01-01')
        end as date_sort,
        current_date as snapshot_date,
        md5(cast(coalesce(cast(suvida_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(num_pcp_visits_ytd as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(last_pcp_appt_date as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(location_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(provider_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(recent_come_back_care_note_text as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(priority as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(category as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as integration_skey
    from patient_category
)

select * exclude payer_plan_program_type
from final
order by
    date_sort desc,
    case when category in ('UNESTABLISHED', 'UNENGAGED') then payer_plan_program_type end,
    category,
    num_pcp_visits_ytd,
    priority