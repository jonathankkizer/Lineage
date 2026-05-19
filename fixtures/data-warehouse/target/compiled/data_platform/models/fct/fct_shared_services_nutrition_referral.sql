with staging as (
    select * from dw_dev.dev_jkizer_staging.stg_airtable_shared_services_nutrition_referral
),

final as (
    select
        -- identifiers
        airtable_id,
        md5(cast(coalesce(cast(airtable_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(last_modified_at as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as nutrition_referral_skey,
        suvida_id,
        elation_id,
        referral_id,
        integration_skey,
        integration_unique_key,

        -- patient demographics
        full_name,
        birth_date,
        payer_member_id,
        payer_name,
        phone,
        phone_type,
        secondary_phone,
        secondary_phone_type,
        email_to,

        -- location & provider context
        location_name,
        elation_location_name,
        elation_provider_name,
        provider_name,

        -- referral metadata
        referral_date,
        referral_body_text,
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
        case when array_contains('1:1 Nutrition'::variant, split(care_programs_needed, ' | '))
            then 1 else 0 end                                                   as is_care_program_nutrition_1on1,
        case when array_contains('Sabor y Vida'::variant, split(care_programs_needed, ' | '))
            then 1 else 0 end                                                   as is_care_program_sabor_y_vida,
        case when array_contains('Food as Medicine'::variant, split(care_programs_needed, ' | '))
            then 1 else 0 end                                                   as is_care_program_food_as_medicine,
        case when array_contains('FoodRx'::variant, split(care_programs_needed, ' | '))
            then 1 else 0 end                                                   as is_care_program_food_rx,
        case when array_contains('Su Bienestar'::variant, split(care_programs_needed, ' | '))
            then 1 else 0 end                                                   as is_care_program_su_bienestar,
        case when is_active_assignment
            then 1 else 0 end                                                   as is_active_assignment,

        -- assigned provider
        assigned_rd_email,
        assigned_rd_id,
        assigned_rd_name,
        automation_trigger_provider_assignment_at,

        -- program enrollment
        case when is_fap_enrolled
            then 1 else 0 end                                                   as is_fap_enrolled,
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

        -- document / referral source
        document_date,
        creation_date,
        created_by_user_name,
        signed_by_username,
        signed_date,
        signed_datetime,

        -- internal notes
        internal_note,
        internal_note_last_updated_date,
        compas_note,

        -- outreach activity
        outreach_1_result,
        outreach_1_user_name,
        outreach_1_user_id,
        outreach_1_user_email,
        outreach_1_datetime,

        -- clinical values: BP (most recent, baseline, derived)
        most_recent_bp_date,
        most_recent_bp_systolic,
        most_recent_bp_diastolic,
        bp_date_closest_to_referral,
        bp_closest_to_referral,
        try_to_number(split_part(bp_closest_to_referral, '/', 1))               as systolic_bp_closest_to_referral,
        try_to_number(split_part(bp_closest_to_referral, '/', 2))               as diastolic_bp_closest_to_referral,
        case when most_recent_bp_systolic >= 140
            then 1 else 0 end                                                   as most_recent_bp_uncontrolled,
        case when most_recent_bp_date <> bp_date_closest_to_referral
            then most_recent_bp_systolic
                - try_to_number(split_part(bp_closest_to_referral, '/', 1))
            else null end                                                       as bp_change,
        case when most_recent_bp_systolic
                < try_to_number(split_part(bp_closest_to_referral, '/', 1))
            and most_recent_bp_date <> bp_date_closest_to_referral
            then 1 else 0 end                                                   as is_bp_improved,

        -- clinical values: A1C (most recent, baseline, derived)
        most_recent_a1c_date,
        most_recent_a1c,
        a1c_date_closest_to_referral,
        a1c_closest_to_referral,
        case when most_recent_a1c >= 8
            then 1 else 0 end                                                   as most_recent_a1c_uncontrolled,
        case when most_recent_a1c_date <> a1c_date_closest_to_referral
            then most_recent_a1c - a1c_closest_to_referral
            else null end                                                       as a1c_change,
        case when most_recent_a1c < a1c_closest_to_referral
            and most_recent_a1c_date <> a1c_date_closest_to_referral
            then 1 else 0 end                                                   as is_a1c_improved,

        -- clinical values: lipids (most recent + uncontrolled)
        most_recent_hdl_date,
        most_recent_hdl,

        most_recent_ldl_date,
        most_recent_ldl,
        case when most_recent_ldl >= 100
            then 1 else 0 end                                                   as most_recent_ldl_uncontrolled,

        most_recent_triglyceride_date,
        most_recent_triglyceride,
        case when most_recent_triglyceride > 150
            then 1 else 0 end                                                   as most_recent_triglyceride_uncontrolled,

        most_recent_total_cholesterol_date,
        most_recent_total_cholesterol,
        case when most_recent_total_cholesterol > 200
            then 1 else 0 end                                                   as most_recent_total_cholesterol_uncontrolled,

        -- source / Elation tag context
        source_type,
        tag_value,
        tag_creation_datetime,
        tag_created_by_user_id,
        active_tag_list,

        -- audit
        created_at,
        created_by_name,
        created_by_id,
        created_by_email,
        last_modified_at,
        last_modified_by_name,
        last_modified_by_id,
        last_modified_by_email,
        run_datetime,
        snapshot_rank,

        -- computed: stage flags
        case when referral_stage in (
                'New - Needs Screening',
                'Initial Screening Complete',
                'Engaged')
            then 1 else 0 end                                                   as is_open,
        case when referral_stage in ('Graduated', 'Removed')
            then 1 else 0 end                                                   as is_closed,
        case when referral_stage = 'Graduated'
            then 1 else 0 end                                                   as is_graduated,

        -- computed: appointment engagement
        case when first_nutrition_appt_date is not null
            then 1 else 0 end                                                   as has_had_first_appointment,
        case when next_nutrition_appt_date is not null
            then 1 else 0 end                                                   as has_scheduled_appointment,

        -- computed: program completion (supports TE-009)
        case when fap_completion_date is not null
            then 1 else 0 end                                                   as is_fap_complete,
        case when next_fap_form_due <= current_date()
            and fap_completion_date is null
            then 1 else 0 end                                                   as is_next_fap_due,

        -- computed: timeliness
        datediff(day, referral_date, current_date())                            as days_since_referral,
        datediff(day, referral_date, first_nutrition_appt_date)                 as days_referral_to_first_appt

    from staging
)

select * from final