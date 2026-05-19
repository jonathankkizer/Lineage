
  create or replace   view dw_dev.dev_jkizer_staging.stg_airtable_shared_services_mh_referral
  
  copy grants
  
  
  as (
    with parsing_data as (
    select
        airtable_id,
        run_datetime,
        parse_json(workflow_fields) as j
    from source_prod.airtable.src_airtable_shared_services_mental_health_referral
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
        array_contains('1:1 Therapy (CoCM)'::variant, j:"Care Programs Needed")        as is_care_program_therapy_1on1_cocm,
        array_contains('MH Workshop'::variant, j:"Care Programs Needed")                as is_care_program_mh_workshop,
        array_contains('Group Grief Therapy'::variant, j:"Care Programs Needed")        as is_care_program_group_grief_therapy,
        array_contains('GG Waitlist'::variant, j:"Care Programs Needed")                as is_care_program_gg_waitlist,
        array_contains('Viviendo Con el Duelo'::variant, j:"Care Programs Needed")      as is_care_program_viviendo_con_el_duelo,

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

        try_to_date(j:"last_pcp_appt_date"::string) as last_pcp_appt_date,
        try_to_date(j:"next_pcp_appt_date"::string) as next_pcp_appt_date,
        try_to_date(j:"next_careteam_appt_date"::string) as next_careteam_appt_date,

        j:"Assigned MH Provider":"email"::string as assigned_mh_provider_email,
        j:"Assigned MH Provider":"id"::string as assigned_mh_provider_id,
        j:"Assigned MH Provider":"name"::string as assigned_mh_provider_name,
        j:"Call Patient"::string as call_patient,
        try_to_date(j:"Graduation Date"::string) as graduation_date,
        j:"Internal Note"::string as internal_note,
        try_to_date(j:"Internal Note Last Updated Date"::string) as internal_note_last_updated_date,
        j:"Transportation Insecurity"::string as transportation_insecurity,
        j:"Contact Details"::string as contact_details,
        j:"Other details"::string as other_details,
 
        try_to_date(j:"first_mh_appt_date"::string) as first_mh_appt_date,
        try_to_date(j:"last_mh_appt_date"::string) as last_mh_appt_date,
        try_to_date(j:"next_mh_appt_date"::string) as next_mh_appt_date,
        j:"num_mh_visits_ytd"::float as num_mh_visits_ytd,
        j:"mh_appt_completion_rate_rolling_12"::float as mh_appt_completion_rate_rolling_12,
        j:"mh_appt_cancelled_rate_rolling_12"::float as mh_appt_cancelled_rate_rolling_12,
        j:"mh_appt_no_show_rate_rolling_12"::float as mh_appt_no_show_rate_rolling_12,

        try_to_date(j:"most_recent_phq_9_date"::string) as most_recent_phq_9_date,
        j:"most_recent_phq_9_value"::float as most_recent_phq_9_value,
        try_to_date(j:"second_most_recent_phq_9_date"::string) as second_most_recent_phq_9_date,
        j:"second_most_recent_phq_9_value"::float as second_most_recent_phq_9_value,

        try_to_date(j:"most_recent_phq_2_date"::string) as most_recent_phq_2_date,
        j:"most_recent_phq_2_value"::float as most_recent_phq_2_value,
        try_to_date(j:"second_most_recent_phq_2_date"::string) as second_most_recent_phq_2_date,
        j:"second_most_recent_phq_2_value"::float as second_most_recent_phq_2_value,

        try_to_date(j:"most_recent_gad_7_date"::string) as most_recent_gad_7_date,
        j:"most_recent_gad_7_value"::float as most_recent_gad_7_value,
        try_to_date(j:"second_most_recent_gad_7_date"::string) as second_most_recent_gad_7_date,
        j:"second_most_recent_gad_7_value"::float as second_most_recent_gad_7_value,

        j:"📞 Outreach 1 - Result"::string as outreach_1_result,
        j:"📞 Outreach 1 - Who":"name"::string as outreach_1_user_name,
        j:"📞 Outreach 1 - Who":"id"::string as outreach_1_user_id,
        j:"📞 Outreach 1 - Who":"email"::string as outreach_1_user_email,
        try_to_timestamp_ntz(j:"📞 Outreach 1 - When"::string) as outreach_1_datetime,
        j:"📞 Outreach 2 - Result"::string as outreach_2_result,
        j:"📞 Outreach 2 - Who":"name"::string as outreach_2_user_name,
        j:"📞 Outreach 2 - Who":"id"::string as outreach_2_user_id,
        j:"📞 Outreach 2 - Who":"email"::string as outreach_2_user_email,
        try_to_timestamp_ntz(j:"📞 Outreach 2 - When"::string) as outreach_2_datetime,
        j:"🧭 Compas Note"::string as compas_note,

        j:"source_type"::string as source_type,
        j:"tag_value"::string as tag_value,
        try_to_timestamp_ntz(j:"tag_creation_datetime"::string) as tag_creation_datetime,
        try_to_timestamp_ntz(j:"tag_deletion_datetime"::string) as tag_deletion_datetime,
        j:"tag_created_by_user_id"::string as tag_created_by_user_id,
        j:"active_tag_list"::string as active_tag_list

    from parsing_data
)

select
    *,
    row_number() over (partition by airtable_id order by last_modified_at desc) as snapshot_rank
from type_conversion
  );

