

select
    -- identifiers
    airtable_id,
    nutrition_referral_skey,
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
    is_care_program_nutrition_1on1,
    is_care_program_sabor_y_vida,
    is_care_program_food_as_medicine,
    is_care_program_food_rx,
    is_care_program_su_bienestar,
    is_active_assignment,

    -- assigned provider
    assigned_rd_email,
    assigned_rd_id,
    assigned_rd_name,
    automation_trigger_provider_assignment_at,

    -- program enrollment
    is_fap_enrolled,
    fap_completion_date,
    next_fap_form_due,
    graduation_date,

    -- appointment history
    first_nutrition_appt_date,
    last_nutrition_appt_date,
    next_nutrition_appt_date,
    last_pcp_appt_date,
    next_pcp_appt_date,
    next_careteam_appt_date,

    -- visit metrics
    num_nutrition_visits_ytd,
    nutrition_appt_completion_rate_rolling_12,
    nutrition_appt_cancelled_rate_rolling_12,
    nutrition_appt_no_show_rate_rolling_12,

    -- utilization context
    census_rolling_12_ip_admit,
    census_rolling_3_ip_admit,

    -- internal notes
    internal_note,
    internal_note_last_updated_date,
    compas_note,

    -- referral source / author
    created_by_user_name,
    signed_by_username,

    -- outreach activity
    outreach_1_result,
    outreach_1_user_name,
    outreach_1_user_id,
    outreach_1_user_email,
    outreach_1_datetime,

    -- clinical values (most recent at time of Airtable sync)
    most_recent_bp_date,
    most_recent_bp_systolic,
    most_recent_bp_diastolic,
    most_recent_a1c_date,
    most_recent_a1c,
    most_recent_hdl_date,
    most_recent_hdl,
    most_recent_ldl_date,
    most_recent_ldl,
    most_recent_ldl_uncontrolled,
    most_recent_triglyceride_date,
    most_recent_triglyceride,
    most_recent_triglyceride_uncontrolled,
    most_recent_total_cholesterol_date,
    most_recent_total_cholesterol,
    most_recent_total_cholesterol_uncontrolled,

    -- baseline values closest to referral date
    bp_date_closest_to_referral,
    bp_closest_to_referral,
    systolic_bp_closest_to_referral,
    diastolic_bp_closest_to_referral,
    is_bp_improved,
    most_recent_bp_uncontrolled,
    bp_change,

    a1c_date_closest_to_referral,
    a1c_closest_to_referral,
    is_a1c_improved,
    most_recent_a1c_uncontrolled,
    a1c_change,

    -- source / Elation tag context
    source_type,
    tag_value,
    tag_creation_datetime,
    tag_created_by_user_id,
    active_tag_list,

    -- audit
    created_at,
    last_modified_at,
    snapshot_rank,

    -- computed flags
    is_open,
    is_closed,
    is_graduated,
    has_had_first_appointment,
    has_scheduled_appointment,
    is_fap_complete,
    is_next_fap_due,
    days_since_referral,
    days_referral_to_first_appt

from dw_dev.dev_jkizer.fct_shared_services_nutrition_referral
where snapshot_rank = 1