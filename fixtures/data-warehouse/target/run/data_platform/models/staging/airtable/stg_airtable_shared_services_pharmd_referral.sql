
  create or replace   view dw_dev.dev_jkizer_staging.stg_airtable_shared_services_pharmd_referral
  
  copy grants
  
  
  as (
    with parsing_data as (
    select
        airtable_id,
        run_datetime,
        parse_json(workflow_fields) as j
    from source_prod.airtable.src_airtable_pharmacy_operations_workflow
),

type_conversion as (
    select
        airtable_id,
        run_datetime,

        try_to_timestamp_ntz(j:"Last Modified"::string) as last_modified_at,
        j:"Last Modified By":"name"::string as last_modified_by_name,
        j:"Last Modified By":"id"::string as last_modified_by_id,
        j:"Last Modified By":"email"::string as last_modified_by_email,
        j:"Elation URL"::string as elation_url,

        j:"Suvida ID"::string as suvida_id,
        j:"First Name"::string as first_name,
        j:"Last Name"::string as last_name,
        try_to_date(j:"DOB"::string) as birth_date,
        j:"Primary Phone Number"::string as primary_phone_number,
        j:"Secondary Phone Number"::string as secondary_phone_number,
        j:"Location Name"::string as location_name,
        j:"Provider Name"::string as provider_name,
        j:"Payer"::string as payer_name,
        j:"Patient Tags"::string as patient_tags,
        j:"Subienestar Plus "::string as subienestar_plus,
        try_to_boolean(j:"Duplicate"::string) as is_duplicate,

        j:"PharmD"::string as pharmd_assignee_name,
        array_to_string(j:"PharmD Programs", ' | ') as pharmd_programs,
        array_contains('Curbside'::variant, j:"PharmD Programs") as is_pharmd_program_curbside,
        array_contains('DM'::variant, j:"PharmD Programs")       as is_pharmd_program_dm,
        array_contains('HTN'::variant, j:"PharmD Programs")      as is_pharmd_program_htn,
        array_contains('CHF'::variant, j:"PharmD Programs")      as is_pharmd_program_chf,
        array_contains('COPD'::variant, j:"PharmD Programs")     as is_pharmd_program_copd,
        j:"PharmD Program Enrollment"::string as pharmd_program_enrollment,
        try_to_number(j:"Program Duration"::string) as program_duration,

        j:"Enrollment Status"::string as enrollment_status,
        j:"Scheduling Status"::string as scheduling_status,
        j:"🧭 Compas Status"::string as compas_status,
        j:"🧭 Compas Note"::string as compas_note,
        j:"Enrollment Notes"::string as enrollment_notes,
        j:"Follow Up Note"::string as follow_up_note,
        j:"Scheduling Notes"::string as scheduling_notes,

        try_to_date(j:"Referred Date"::string) as referred_date,
        try_to_date(j:"Task Date"::string) as task_date,
        try_to_date(j:"Disenrollment Date"::string) as disenrollment_date,
        try_to_date(j:"Next PharmD Visit Date"::string) as next_pharmd_visit_date,
        try_to_date(j:"Last PharmD Visit Date"::string) as last_pharmd_visit_date,
        try_to_date(j:"Next PCP Visit Date"::string) as next_pcp_visit_date,
        try_to_date(j:"Last PCP Visit Date"::string) as last_pcp_visit_date,

        j:"YTD PharmD Visits"::float as ytd_pharmd_visits,
        j:"YTD PCP Visits"::float as ytd_pcp_visits,
        j:"Pharmacy Appt Completion Rate"::float as pharmacy_appt_completion_rate,
        j:"Cancel Rate % (For PharmD Visits only)"::float as pharmd_visit_cancel_rate,
        j:"No Show Rate % (For PharmD Visits only)"::float as pharmd_visit_no_show_rate,

        j:"Reason for Referral"::string as reason_for_referral,
        j:"Signer of Referral"::string as signer_of_referral,
        j:"Dx / Problem List"::string as dx_problem_list,
        j:"Dx within Referral"::string as dx_within_referral,

        iff(j:"PharmD-CHF Tag?" is not null, true, false)  as is_pharmd_chf_tag,
        iff(j:"PharmD-COPD Tag?" is not null, true, false) as is_pharmd_copd_tag,
        iff(j:"PharmD-DM Tag?" is not null, true, false)   as is_pharmd_dm_tag,
        iff(j:"PharmD-HTN Tag?" is not null, true, false)  as is_pharmd_htn_tag,

        try_to_date(j:"Date Labs - Most Recent A1c"::string) as most_recent_a1c_date,
        j:"Labs - Most Recent A1c"::float as most_recent_a1c_value,
        try_to_date(j:"Date Labs - 2nd Most Recent A1c"::string) as second_most_recent_a1c_date,
        j:"Labs - 2nd Most Recent A1c"::float as second_most_recent_a1c_value,
        try_to_date(j:"Date Labs - Most Recent HR"::string) as most_recent_hr_date,
        j:"Labs - Most Recent HR"::float as most_recent_hr_value,
        try_to_date(j:"Date Labs - Second Most Recent HR"::string) as second_most_recent_hr_date,
        j:"Labs - Second Most Recent HR"::float as second_most_recent_hr_value,

        j:"integration_skey"::string as integration_skey,
        j:"referral_skey"::string as referral_skey

    from parsing_data
)

select
    *,
    row_number() over (partition by airtable_id order by last_modified_at desc) as snapshot_rank
from type_conversion
where last_modified_at is not null
  );

