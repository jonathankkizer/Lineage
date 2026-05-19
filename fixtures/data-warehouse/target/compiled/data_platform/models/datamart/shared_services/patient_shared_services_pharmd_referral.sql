

select
    -- identifiers
    airtable_id,
    pharmd_referral_skey,
    suvida_id,

    -- patient demographics
    first_name,
    last_name,
    birth_date,
    primary_phone_number,
    secondary_phone_number,
    patient_tags,
    subienestar_plus,

    -- location & provider context
    location_name,
    provider_name,
    payer_name,

    -- referral metadata
    referred_date,
    task_date,
    reason_for_referral,
    signer_of_referral,
    dx_problem_list,
    dx_within_referral,

    -- assigned pharmacist
    pharmd_assignee_name,

    -- program enrollment
    pharmd_programs,
    pharmd_program_enrollment,
    program_duration,
    is_pharmd_program_curbside,
    is_pharmd_program_dm,
    is_pharmd_program_htn,
    is_pharmd_program_chf,
    is_pharmd_program_copd,
    is_pharmd_chf_tag,
    is_pharmd_copd_tag,
    is_pharmd_dm_tag,
    is_pharmd_htn_tag,
    disenrollment_date,

    -- workflow status
    enrollment_status,
    scheduling_status,
    compas_status,
    compas_note,
    enrollment_notes,
    follow_up_note,
    scheduling_notes,

    -- appointment history
    next_pharmd_visit_date,
    last_pharmd_visit_date,
    next_pcp_visit_date,
    last_pcp_visit_date,

    -- visit metrics
    ytd_pharmd_visits,
    ytd_pcp_visits,
    pharmacy_appt_completion_rate,
    pharmd_visit_cancel_rate,
    pharmd_visit_no_show_rate,

    -- clinical assessments
    most_recent_a1c_date,
    most_recent_a1c_value,
    second_most_recent_a1c_date,
    second_most_recent_a1c_value,
    most_recent_hr_date,
    most_recent_hr_value,
    second_most_recent_hr_date,
    second_most_recent_hr_value,

    -- links
    elation_url,

    -- audit
    last_modified_at,
    last_modified_by_name,
    last_modified_by_email,
    snapshot_rank,

    -- computed flags
    is_open,
    is_closed,
    is_enrolled,
    is_removed,
    has_had_visit,
    has_scheduled_visit,
    is_a1c_improved,
    days_since_referral,
    days_referral_to_last_visit

from dw_dev.dev_jkizer.fct_shared_services_pharmd_referral
where snapshot_rank = 1