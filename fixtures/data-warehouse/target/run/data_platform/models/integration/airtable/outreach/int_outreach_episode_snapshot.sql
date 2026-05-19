
  
    

create or replace transient table dw_dev.dev_jkizer.int_outreach_episode_snapshot
    copy grants
    
    
    as (/*
  Daily snapshot of outreach cohort membership. One row per (suvida_id, cohort_key, snapshot_date).

  Purpose: source of truth for which patients belong to which outreach cohort each day.
  Drives episode open/close logic in int_outreach_episode and retains an indefinite history
  for analytics.

  Schema strategy: a small set of common evidence columns (typed, present across cohorts) plus
  a VARIANT `evidence` column for cohort-specific drill-down. This keeps the schema stable as
  new cohorts are added — only the `evidence` payload varies per cohort. `qualifying_reason`
  is a short label suitable for at-a-glance display in Airtable.

  Behavior:
  - delete+insert on snapshot_date — re-running the same day overwrites that day's rows
  - All prior snapshot_dates are retained indefinitely

  Cohorts implemented:
  - new_patient_engagement (NPE): newly-assigned, never-seen patients past the scheduling SLA
      (60 days normal, 30 days CSNP) but still within the 120-day newly-assigned window.
  - come_back_to_care (CBTC): established patients without a future PCP appt, overdue by
      90 days (normal) or 30 days (high-risk). Upper-bounded at 9 months so CBTC and HTR
      Unengaged are mutually exclusive.
  - hard_to_reach (HTR): two sub-paths sharing a cohort —
      `unestablished` = never had a PCP appt + assigned >120 days ago;
      `unengaged` = had a PCP appt > 9 months ago.
      Active patients only; no future PCP appt.
  - churn: recently disenrolled patients (is_active_assignment=0, eligibility ended in the
      last 12 months) for win-back outreach. NOTE: 12-month window is a placeholder pending
      business confirmation.
*/



with patient_base as (
    select
        suvida_id,
        is_active_assignment,
        elation_status,
        active_tag_list,
        last_pcp_appt_date,
        next_pcp_appt_date,
        eligibility_start_month,
        eligibility_max_month,
        last_awv_date,
        high_risk_patient,
        payer_plan_program_type
    from dw_dev.dev_jkizer.patient_summary
),

new_patient_engagement as (
    select
        suvida_id,
        'new_patient_engagement' as cohort_key,
        case
            when upper(payer_plan_program_type) = 'CSNP' then 'csnp_unscheduled_30d'
            else 'normal_unscheduled_60d'
        end as qualifying_reason,
        last_pcp_appt_date,
        next_pcp_appt_date,
        eligibility_start_month,
        eligibility_max_month,
        (high_risk_patient = 1) as high_risk_ind,
        last_awv_date,
        object_construct(
            'threshold_days', iff(upper(payer_plan_program_type) = 'CSNP', 30, 60),
            'days_since_eligibility_start', datediff('day', eligibility_start_month, current_date),
            'is_csnp', upper(payer_plan_program_type) = 'CSNP'
        ) as evidence
    from patient_base
    where is_active_assignment = 1
        and (elation_status != 'deceased' or elation_status is null)
        and not lower(active_tag_list) like lower('%**HOSPICE**%')
        and last_pcp_appt_date is null
        and next_pcp_appt_date is null
        and eligibility_start_month is not null
        and eligibility_start_month >= dateadd(day, -120, current_date)
        and eligibility_start_month < case
                when upper(payer_plan_program_type) = 'CSNP' then dateadd(day, -30, current_date)
                else dateadd(day, -60, current_date)
            end
),

come_back_to_care as (
    select
        suvida_id,
        'come_back_to_care' as cohort_key,
        case
            when high_risk_patient = 1 then 'high_risk_overdue_30d'
            else 'normal_overdue_90d'
        end as qualifying_reason,
        last_pcp_appt_date,
        next_pcp_appt_date,
        eligibility_start_month,
        eligibility_max_month,
        (high_risk_patient = 1) as high_risk_ind,
        last_awv_date,
        object_construct(
            'threshold_days', iff(high_risk_patient = 1, 30, 90),
            'days_since_last_pcp_visit', datediff('day', last_pcp_appt_date, current_date)
        ) as evidence
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
        and last_pcp_appt_date >= dateadd(month, -9, current_date)
),

hard_to_reach as (
    select
        suvida_id,
        'hard_to_reach' as cohort_key,
        case
            when last_pcp_appt_date is null then 'unestablished'
            else 'unengaged'
        end as qualifying_reason,
        last_pcp_appt_date,
        next_pcp_appt_date,
        eligibility_start_month,
        eligibility_max_month,
        (high_risk_patient = 1) as high_risk_ind,
        last_awv_date,
        case
            when last_pcp_appt_date is null then
                object_construct(
                    'days_since_eligibility_start', datediff('day', eligibility_start_month, current_date)
                )
            else
                object_construct(
                    'days_since_last_pcp_visit', datediff('day', last_pcp_appt_date, current_date)
                )
        end as evidence
    from patient_base
    where is_active_assignment = 1
        and (elation_status != 'deceased' or elation_status is null)
        and not lower(active_tag_list) like lower('%**HOSPICE**%')
        and next_pcp_appt_date is null
        and (
            (last_pcp_appt_date is null
                and eligibility_start_month < dateadd(day, -120, current_date))
            or (last_pcp_appt_date is not null
                and last_pcp_appt_date < dateadd(month, -9, current_date))
        )
),

churn as (
    select
        suvida_id,
        'churn' as cohort_key,
        'recently_disenrolled' as qualifying_reason,
        last_pcp_appt_date,
        next_pcp_appt_date,
        eligibility_start_month,
        eligibility_max_month,
        (high_risk_patient = 1) as high_risk_ind,
        last_awv_date,
        object_construct(
            'days_since_disenrollment', datediff('day', eligibility_max_month, current_date)
        ) as evidence
    from patient_base
    where is_active_assignment = 0
        and (elation_status != 'deceased' or elation_status is null)
        and not lower(active_tag_list) like lower('%**HOSPICE**%')
        and eligibility_max_month is not null
        and eligibility_max_month < date_trunc('month', current_date)
        and eligibility_max_month >= dateadd(month, -12, current_date)
),

all_cohorts as (
    select * from new_patient_engagement
    union all
    select * from come_back_to_care
    union all
    select * from hard_to_reach
    union all
    select * from churn
),

final as (
    select
        suvida_id,
        cohort_key,
        current_date as snapshot_date,
        qualifying_reason,
        last_pcp_appt_date,
        next_pcp_appt_date,
        eligibility_start_month,
        eligibility_max_month,
        high_risk_ind,
        last_awv_date,
        evidence
    from all_cohorts
)

select * from final
    )
;


  