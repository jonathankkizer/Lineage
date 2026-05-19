
  
    

create or replace transient table dw_dev.dev_jkizer.fct_shared_services_pt_referral
    copy grants
    
    
    as (with staging as (
    select * from dw_dev.dev_jkizer_staging.stg_airtable_shared_services_physical_therapy_referral
),

final as (
    select
        -- identifiers
        airtable_id,
        md5(cast(coalesce(cast(airtable_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(last_modified_at as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as pt_referral_skey,
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
        is_care_program_pt_1on1,
        is_active_assignment,

        -- assigned provider
        assigned_pt_email,
        assigned_pt_id,
        assigned_pt_name,

        -- program enrollment
        is_fap_enrolled,
        fap_completion_date,
        next_fap_form_due,

        -- plan of care
        poc_signed,
        poc_visits_per_week,
        poc_weeks,
        scheduled_out,

        -- evaluation & certification
        initial_evaluation_date,
        last_re_evaluation_date,
        most_recent_eval_helper,
        certification_end_date,
        progress_update_due,
        discharge_date,
        discharge_reason,

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

        -- clinical assessments — TUG (Timed Up and Go; lower = better)
        most_recent_pre_tug_date,
        most_recent_pre_tug_value,
        second_most_recent_pre_tug_date,
        second_most_recent_pre_tug_value,

        -- clinical assessments — Chair Stand (higher = better)
        most_recent_pre_chair_stand_date,
        most_recent_pre_chair_stand_value,
        most_recent_post_chair_stand_date,
        most_recent_post_chair_stand_value,

        -- fall risk / utilization (supports TE-018)
        rolling_12_fall_er_visits,
        rolling_12_fall_ip_visits,

        -- utilization context
        census_rolling_12_ip_admit,
        census_rolling_3_ip_admit,

        -- SDOH / fall screening (drives is_fall_screening_complete below)
        sdoh_form_due_ind,

        -- document / referral source
        document_date,
        creation_date,
        created_by_user_name,
        sent_by_user_name,
        signed_by_username,
        signed_date,
        signed_datetime,

        -- internal notes
        internal_note,
        date_of_last_internal_note,
        compas_note,

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
        referral_stage in (
            'Waitlist',
            'New - Needs Evaluation',
            'Initial Evaluation Scheduled',
            'Engaged',
            'Initial Evaluation Complete'
        )                                                                                   as is_open,
        referral_stage in ('Removed', 'Discharged')                                         as is_closed,

        -- computed: program completion (TE-015)
        referral_stage = 'Discharged'                                                       as is_discharged,
        poc_signed                                                                          as is_poc_signed,
        poc_visits_per_week * poc_weeks                                                     as total_poc_visits_planned,
        datediff(
            day,
            initial_evaluation_date,
            coalesce(discharge_date, current_date())
        )                                                                                   as days_in_program,

        -- computed: appointment engagement
        first_pt_appt_date is not null                                                      as has_had_first_appointment,
        next_pt_appt_date is not null                                                       as has_scheduled_appointment,

        -- computed: fall prevention screening compliance (TE-014)
        sdoh_form_due_ind = 0                                                               as is_fall_screening_complete,

        -- computed: functional improvement (TE-016)
        most_recent_pre_tug_value < second_most_recent_pre_tug_value                        as is_functionally_improved_tug,
        most_recent_post_chair_stand_value > most_recent_pre_chair_stand_value              as is_functionally_improved_chair,

        -- computed: timeliness
        datediff(day, referral_date, current_date())                                        as days_since_referral,
        datediff(day, referral_date, first_pt_appt_date)                                    as days_referral_to_first_appt

    from staging
)

select * from final
    )
;


  