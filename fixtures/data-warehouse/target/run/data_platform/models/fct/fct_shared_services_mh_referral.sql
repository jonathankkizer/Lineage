
  
    

create or replace transient table dw_dev.dev_jkizer.fct_shared_services_mh_referral
    copy grants
    
    
    as (with staging as (
    select * from dw_dev.dev_jkizer_staging.stg_airtable_shared_services_mh_referral
),

final as (
    select
        -- identifiers
        airtable_id,
        md5(cast(coalesce(cast(airtable_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(last_modified_at as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as mh_referral_skey,
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
        transportation_insecurity,
        contact_details,
        other_details,
        call_patient,

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
        is_fap_enrolled,
        fap_completion_date,
        next_fap_form_due,
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

        -- clinical assessments — PHQ-9 (depression)
        most_recent_phq_9_date,
        most_recent_phq_9_value,
        second_most_recent_phq_9_date,
        second_most_recent_phq_9_value,

        -- clinical assessments — PHQ-2 (brief depression screening)
        most_recent_phq_2_date,
        most_recent_phq_2_value,
        second_most_recent_phq_2_date,
        second_most_recent_phq_2_value,

        -- clinical assessments — GAD-7 (anxiety)
        most_recent_gad_7_date,
        most_recent_gad_7_value,
        second_most_recent_gad_7_date,
        second_most_recent_gad_7_value,

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

        -- source / Elation tag context
        source_type,
        tag_value,
        tag_creation_datetime,
        tag_deletion_datetime,
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

        -- computed: status flags
        referral_status = 'Active'                                              as is_open,
        referral_status in ('Closed', 'Removed')                                as is_closed,
        resolution_state = 'Completed'                                          as is_successfully_resolved,

        -- computed: program completion
        graduation_date is not null                                             as is_graduated,

        -- computed: appointment engagement
        first_mh_appt_date is not null                                          as has_had_first_appointment,
        next_mh_appt_date is not null                                           as has_scheduled_appointment,

        -- computed: clinical outcome improvement (lower score = better)
        most_recent_phq_9_value < second_most_recent_phq_9_value                as is_phq9_improved,
        most_recent_phq_2_value < second_most_recent_phq_2_value                as is_phq2_improved,
        most_recent_gad_7_value < second_most_recent_gad_7_value                as is_gad7_improved,

        -- computed: timeliness
        datediff(day, referral_date, current_date())                            as days_since_referral,
        datediff(day, referral_date, first_mh_appt_date)                        as days_referral_to_first_appt

    from staging
)

select * from final
    )
;


  