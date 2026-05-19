

select
    -- identifiers
    airtable_id,
    pt_referral_skey,
    suvida_id,
    elation_id,
    referral_id,

    -- patient demographics
    full_name,
    birth_date,
    payer_member_id,
    payer_name,
    phone,
    phone_type,
    secondary_phone,
    secondary_phone_type,

    -- location & provider context
    location_name,
    elation_location_name,
    elation_provider_name,
    provider_name,

    -- referral metadata
    referral_date,
    referral_icd_list,
    referral_icd_description_list,
    recipient_org_name,
    recipient_specialty,
    clinical_reason,

    -- workflow status
    referral_stage,
    scheduling_stage,
    referral_status,
    removal_reason,
    resolution_state,
    processing_status,
    care_programs_needed,
    is_care_program_pt_1on1,
    is_active_assignment,

    -- assigned provider
    assigned_pt_email,
    assigned_pt_id,
    assigned_pt_name,

    -- plan of care
    poc_signed,
    poc_visits_per_week,
    poc_weeks,
    scheduled_out,
    total_poc_visits_planned,

    -- evaluation & certification
    initial_evaluation_date,
    last_re_evaluation_date,
    certification_end_date,
    progress_update_due,
    discharge_date,
    discharge_reason,
    days_in_program,

    -- appointment history
    first_pt_appt_date,
    last_pt_appt_date,
    next_pt_appt_date,
    last_pcp_appt_date,
    next_pcp_appt_date,
    next_careteam_appt_date,

    -- visit metrics
    num_pt_visits_ytd,
    pt_appt_completion_rate_rolling_12,
    pt_appt_cancelled_rate_rolling_12,
    pt_appt_no_show_rate_rolling_12,

    -- clinical assessments
    most_recent_pre_tug_date,
    most_recent_pre_tug_value,
    second_most_recent_pre_tug_date,
    second_most_recent_pre_tug_value,
    most_recent_pre_chair_stand_date,
    most_recent_pre_chair_stand_value,
    most_recent_post_chair_stand_date,
    most_recent_post_chair_stand_value,

    -- fall risk
    rolling_12_fall_er_visits,
    rolling_12_fall_ip_visits,

    -- SDOH / fall screening (drives is_fall_screening_complete)
    sdoh_form_due_ind,

    -- utilization context
    census_rolling_12_ip_admit,
    census_rolling_3_ip_admit,

    -- internal notes
    internal_note,
    date_of_last_internal_note,
    compas_note,

    -- referral source / author
    created_by_user_name,
    sent_by_user_name,
    signed_by_username,

    -- outreach activity
    outreach_1_result,
    outreach_1_user_name,
    outreach_1_user_id,
    outreach_1_user_email,
    outreach_1_datetime,
    outreach_2_result,
    outreach_2_user_name,
    outreach_2_user_id,
    outreach_2_user_email,
    outreach_2_datetime,
    outreach_3_result,
    outreach_3_user_name,
    outreach_3_user_id,
    outreach_3_user_email,
    outreach_3_datetime,

    -- source / Elation tag context
    source_type,
    tag_value,
    tag_creation_datetime,
    tag_deletion_datetime,
    tag_created_by_user_id,
    active_tag_list,
    cc_labeling_referral_type,

    -- audit
    created_at,
    last_modified_at,
    snapshot_rank,

    -- computed flags
    is_open,
    is_closed,
    is_discharged,
    is_poc_signed,
    has_had_first_appointment,
    has_scheduled_appointment,
    is_fall_screening_complete,
    is_functionally_improved_tug,
    is_functionally_improved_chair,
    days_since_referral,
    days_referral_to_first_appt

from dw_dev.dev_jkizer.fct_shared_services_pt_referral
where snapshot_rank = 1