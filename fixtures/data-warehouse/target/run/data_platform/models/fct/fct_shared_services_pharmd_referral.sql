
  
    

create or replace transient table dw_dev.dev_jkizer.fct_shared_services_pharmd_referral
    copy grants
    
    
    as (with staging as (
    select * from dw_dev.dev_jkizer_staging.stg_airtable_shared_services_pharmd_referral
),

final as (
    select
        -- identifiers
        airtable_id,
        md5(cast(coalesce(cast(airtable_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(last_modified_at as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as pharmd_referral_skey,
        suvida_id,
        integration_skey,
        referral_skey,

        -- patient demographics
        first_name,
        last_name,
        birth_date,
        primary_phone_number,
        secondary_phone_number,
        patient_tags,
        subienestar_plus,
        is_duplicate,

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

        -- clinical assessments — A1C
        most_recent_a1c_date,
        most_recent_a1c_value,
        second_most_recent_a1c_date,
        second_most_recent_a1c_value,

        -- clinical assessments — heart rate
        most_recent_hr_date,
        most_recent_hr_value,
        second_most_recent_hr_date,
        second_most_recent_hr_value,

        -- links
        elation_url,

        -- audit
        last_modified_at,
        last_modified_by_name,
        last_modified_by_id,
        last_modified_by_email,
        run_datetime,
        snapshot_rank,

        -- computed: status flags
        compas_status = 'Open'                                                  as is_open,
        compas_status = 'Closed'                                                as is_closed,
        enrollment_status = 'Enrolled'                                          as is_enrolled,
        enrollment_status ilike '%remove%'                                      as is_removed,

        -- computed: appointment engagement
        last_pharmd_visit_date is not null                                      as has_had_visit,
        next_pharmd_visit_date is not null                                      as has_scheduled_visit,

        -- computed: clinical improvement (lower A1c = better)
        most_recent_a1c_value < second_most_recent_a1c_value                    as is_a1c_improved,

        -- computed: timeliness
        datediff(day, referred_date, current_date())                            as days_since_referral,
        datediff(day, referred_date, last_pharmd_visit_date)                    as days_referral_to_last_visit

    from staging
)

select * from final
    )
;


  