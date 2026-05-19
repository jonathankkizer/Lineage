
  create or replace   view dw_dev.dev_jkizer_staging.stg_airtable_shared_services_nutrition_referral
  
  copy grants
  
  
  as (
    with parsing_data as (
    select
        airtable_id,
        run_datetime,
        parse_json(workflow_fields) as j
    from source_prod.airtable.src_airtable_shared_services_nutrition_referral
),

type_conversion as (
    select
        airtable_id,
        run_datetime,

        try_to_timestamp_ntz(j:"Created"::string) as created_at,
        j:"Created By":"name"::string as created_by_name,
        j:"Created By":"id"::string as created_by_id,
        j:"Created By":"email"::string as created_by_email,
        try_to_timestamp_ntz(j:"Last Modified"::string) as last_modified_at,
        j:"Last Modified By":"name"::string as last_modified_by_name,
        j:"Last Modified By":"id"::string as last_modified_by_id,
        j:"Last Modified By":"email"::string as last_modified_by_email,
        j:"Display Name"::string as display_name,
        j:"Open Chart":"url"::string as open_chart_url,
        j:"Patient Call Deep Link"::string as patient_call_deep_link,
 
        j:"Referral Stage"::string as referral_stage,
        j:"Scheduling Stage"::string as scheduling_stage,
        j:"Status"::string as referral_status,
        j:"Removal Reason"::string as removal_reason,
        array_to_string(j:"Care Programs Needed", ' | ') as care_programs_needed,

        j:"suvida_id"::string as suvida_id,
        j:"elation_id"::string as elation_id,
        j:"full_name"::string as full_name,
        j:"elation_patient_url"::string as elation_patient_url,
        j:"elation_provider_name"::string as elation_provider_name,
        j:"elation_location_name"::string as elation_location_name,
        j:"location_name"::string as location_name,
        j:"payer_member_id"::string as payer_member_id,
        j:"payer_name"::string as payer_name,

        try_to_date(j:"birth_date"::string) as birth_date,
        j:"phone"::string as phone,
        j:"phone_type"::string as phone_type,
        j:"secondary_phone"::string as secondary_phone,
        j:"secondary_phone_type"::string as secondary_phone_type,
        j:"email_to"::string as email_to,
 
        j:"census_rolling_12_ip_admit"::float as census_rolling_12_ip_admit,
        j:"census_rolling_3_ip_admit"::float as census_rolling_3_ip_admit,

        j:"referral_id"::string as referral_id,
        try_to_date(j:"referral_date"::string) as referral_date,
        j:"referral_body_text"::string as referral_body_text,
        j:"referral_icd_list"::string as referral_icd_list,
        j:"referral_icd_description_list"::string as referral_icd_description_list,
        j:"recipient_org_name"::string as recipient_org_name,
        j:"recipient_specialty"::string as recipient_specialty,
        j:"resolution_state"::string as resolution_state,
        j:"clinical_reason"::string as clinical_reason,
        j:"processing_status"::string as processing_status,

        try_to_date(j:"document_date"::string) as document_date,
        try_to_date(j:"creation_date"::string) as creation_date,
        j:"created_by_user_name"::string as created_by_user_name,
        j:"provider_name"::string as provider_name,
        j:"signed_by_username"::string as signed_by_username,
        try_to_date(j:"signed_date"::string) as signed_date,
        try_to_timestamp_ntz(j:"signed_datetime"::string) as signed_datetime,

        j:"integration_skey"::string as integration_skey,
        j:"integration_unique_key"::string as integration_unique_key,
        try_to_boolean(j:"is_active_assignment"::string) as is_active_assignment,

        try_to_boolean(j:"is_fap_enrolled"::string) as is_fap_enrolled,
        try_to_date(j:"fap_completion_date"::string) as fap_completion_date,
        try_to_date(j:"next_fap_form_due"::string) as next_fap_form_due,
        try_to_date(j:"Graduation Date"::string) as graduation_date,
 
        try_to_date(j:"last_pcp_appt_date"::string) as last_pcp_appt_date,
        try_to_date(j:"next_pcp_appt_date"::string) as next_pcp_appt_date,
        try_to_date(j:"next_careteam_appt_date"::string) as next_careteam_appt_date,

        j:"Assigned RD Provider":"email"::string as assigned_rd_email,
        j:"Assigned RD Provider":"id"::string    as assigned_rd_id,
        j:"Assigned RD Provider":"name"::string  as assigned_rd_name,
        try_to_timestamp_ntz(j:"Automation trigger: Provider Assignment"::string) as automation_trigger_provider_assignment_at,
        j:"Internal Note"::string as internal_note,
        try_to_date(j:"Internal Note Last Updated Date"::string) as internal_note_last_updated_date,

        j:"📞 Outreach 1 - Result"::string as outreach_1_result,
        j:"📞 Outreach 1 - Who":"name"::string as outreach_1_user_name,
        j:"📞 Outreach 1 - Who":"id"::string as outreach_1_user_id,
        j:"📞 Outreach 1 - Who":"email"::string as outreach_1_user_email,
        try_to_timestamp_ntz(j:"📞 Outreach 1 - When"::string) as outreach_1_datetime,

        try_to_date(j:"first_nutrition_appt_date"::string) as first_nutrition_appt_date,
        try_to_date(j:"last_nutrition_appt_date"::string) as last_nutrition_appt_date,
        try_to_date(j:"next_nutrition_appt_date"::string) as next_nutrition_appt_date,
        j:"num_nutrition_visits_ytd"::float as num_nutrition_visits_ytd,
        j:"nutrition_appt_completion_rate_rolling_12"::float as nutrition_appt_completion_rate_rolling_12,
        j:"nutrition_appt_cancelled_rate_rolling_12"::float as nutrition_appt_cancelled_rate_rolling_12,
        j:"nutrition_appt_no_show_rate_rolling_12"::float as nutrition_appt_no_show_rate_rolling_12,

        j:"🧭 Compas Note"::string as compas_note,

        try_to_date(j:"most_recent_bp_date"::string) as most_recent_bp_date,
        try_to_double(j:"most_recent_bp_systolic"::string) as most_recent_bp_systolic,
        try_to_double(j:"most_recent_bp_diastolic"::string) as most_recent_bp_diastolic,
        try_to_date(j:"most_recent_a1c_date"::string) as most_recent_a1c_date,
        try_to_double(j:"most_recent_a1c"::string) as most_recent_a1c,
        try_to_date(j:"most_recent_hdl_date"::string) as most_recent_hdl_date,
        try_to_double(j:"most_recent_hdl"::string) as most_recent_hdl,
        try_to_date(j:"most_recent_ldl_date"::string) as most_recent_ldl_date,
        try_to_double(j:"most_recent_ldl"::string) as most_recent_ldl,
        try_to_date(j:"most_recent_triglyceride_date"::string) as most_recent_triglyceride_date,
        try_to_double(j:"most_recent_triglyceride"::string) as most_recent_triglyceride,
        try_to_date(j:"most_recent_total_cholesterol_date"::string) as most_recent_total_cholesterol_date,
        try_to_double(j:"most_recent_total_cholesterol"::string) as most_recent_total_cholesterol,

        try_to_date(j:"bp_date_closest_to_referral"::string) as bp_date_closest_to_referral,
        j:"bp_closest_to_referral"::string as bp_closest_to_referral,
        try_to_date(j:"a1c_date_closest_to_referral"::string) as a1c_date_closest_to_referral,
        try_to_double(j:"a1c_closest_to_referral"::string) as a1c_closest_to_referral,

        j:"source_type"::string as source_type,
        j:"tag_value"::string as tag_value,
        try_to_timestamp_ntz(j:"tag_creation_datetime"::string) as tag_creation_datetime,
        j:"tag_created_by_user_id"::string as tag_created_by_user_id,
        j:"active_tag_list"::string as active_tag_list

    from parsing_data
)

select
    *,
    row_number() over (partition by airtable_id order by last_modified_at desc) as snapshot_rank
from type_conversion
  );

