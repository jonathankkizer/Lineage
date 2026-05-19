with attempts_raw as (

    -- Attempt 1
    select
        suvida_id,
        attempt_1_date as attempt_date,
        'Attempt 1' as attempt,
        attempt_1_result as attempt_result,
        attempt_1_who_id as attempt_who_id,
        snapshot_date
    from dw_dev.dev_jkizer_staging.stg_sharepoint_outreach_list
    where attempt_1_date is not null
        and _idx = 1

    union all

    -- Attempt 2
    select
        suvida_id,
        attempt_2_date as attempt_date,
        'Attempt 2' as attempt,
        attempt_2_result as attempt_result,
        attempt_2_who_id as attempt_who_id,
        snapshot_date
    from dw_dev.dev_jkizer_staging.stg_sharepoint_outreach_list
    where attempt_2_date is not null
        and _idx = 1

    union all

    -- Attempt 3
    select
        suvida_id,
        attempt_3_date as attempt_date,
        'Attempt 3' as attempt,
        attempt_3_result as attempt_result,
        attempt_3_who_id as attempt_who_id,
        snapshot_date
    from dw_dev.dev_jkizer_staging.stg_sharepoint_outreach_list
    where attempt_3_date is not null
        and _idx = 1

    union all

    -- Attempt 4
    select
        suvida_id,
        attempt_4_date as attempt_date,
        'Attempt 4' as attempt,
        attempt_4_result as attempt_result,
        attempt_4_who_id as attempt_who_id,
        snapshot_date
    from dw_dev.dev_jkizer_staging.stg_sharepoint_outreach_list
    where attempt_4_date is not null
        and _idx = 1

),

-- Deduplicate attempts (keep latest snapshot)
attempts as (

    select *
    from attempts_raw
    qualify row_number() over (
        partition by suvida_id, attempt, attempt_date
        order by snapshot_date desc
    ) = 1

)

select
    di.suvida_id,
    di.snapshot_date,
    'patient-on-list' as event_type,
    di.full_name,
    di.phone,
    di.dual_status,
    di.preferred_language,
    di.elation_id,
    di.elation_patient_url,
    di.location_name,
    di.provider_name,
    di.category,
    di.priority,
    di.last_pcp_appt_date,
    di.days_since_last_pcp_visit,
    di.num_pcp_visits_ytd,
    di.is_awv_complete_ytd,
    di.cumulative_pcp_visits,
    di.eligibility_start_month,
    di.emr_claims_blended_risk_score_adj_rolling,
    di.outstanding_v28_community_raf,
    di.high_risk_patient,
    di.recent_come_back_care_note_text,
    di.integration_skey,
    a.attempt,
    a.attempt_date,
    a.attempt_result,
    a.attempt_who_id as staff_attempted_id,
    su.display_name as staff_attempted
from dw_dev.dev_jkizer.int_sharepoint_list_outreach_incremental di
left join attempts a
    on di.suvida_id = a.suvida_id
    and di.snapshot_date = a.attempt_date
left join dw_dev.dev_jkizer_staging.stg_sharepoint_site_users su
    on a.attempt_who_id = su.user_id
    and not su.is_deleted