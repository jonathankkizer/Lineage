

select
    -- identifiers
    airtable_id,
    mh_referral_skey,
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
    transportation_insecurity,

    -- location & provider context
    location_name,
    elation_location_name,
    elation_provider_name,
    provider_name,
    contact_details,
    other_details,
    call_patient,

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
    is_care_program_therapy_1on1_cocm,
    is_care_program_mh_workshop,
    is_care_program_group_grief_therapy,
    is_care_program_gg_waitlist,
    is_care_program_viviendo_con_el_duelo,
    is_active_assignment,

    -- assigned provider
    assigned_mh_provider_email,
    assigned_mh_provider_id,
    assigned_mh_provider_name,

    -- program enrollment
    graduation_date,

    -- appointment history
    first_mh_appt_date,
    last_mh_appt_date,
    next_mh_appt_date,
    last_pcp_appt_date,
    next_pcp_appt_date,
    next_careteam_appt_date,

    -- visit metrics
    num_mh_visits_ytd,
    mh_appt_completion_rate_rolling_12,
    mh_appt_cancelled_rate_rolling_12,
    mh_appt_no_show_rate_rolling_12,

    -- clinical assessments
    most_recent_phq_9_date,
    most_recent_phq_9_value,
    second_most_recent_phq_9_date,
    second_most_recent_phq_9_value,
    most_recent_phq_2_date,
    most_recent_phq_2_value,
    second_most_recent_phq_2_date,
    second_most_recent_phq_2_value,
    most_recent_gad_7_date,
    most_recent_gad_7_value,
    second_most_recent_gad_7_date,
    second_most_recent_gad_7_value,

    -- referral source / author
    created_by_user_name,
    signed_by_username,

    -- outreach tracking
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

    -- utilization context
    census_rolling_12_ip_admit,
    census_rolling_3_ip_admit,

    -- internal notes
    internal_note,
    internal_note_last_updated_date,
    compas_note,

    -- source / Elation tag context
    source_type,
    tag_value,
    tag_creation_datetime,
    tag_deletion_datetime,
    tag_created_by_user_id,
    active_tag_list,

    -- audit
    created_at,
    last_modified_at,
    snapshot_rank,

    -- computed flags
    is_open,
    is_closed,
    is_successfully_resolved,
    is_graduated,
    has_had_first_appointment,
    has_scheduled_appointment,
    is_phq9_improved,
    is_phq2_improved,
    is_gad7_improved,
    days_since_referral,
    days_referral_to_first_appt

from dw_dev.dev_jkizer.fct_shared_services_mh_referral
where snapshot_rank = 1