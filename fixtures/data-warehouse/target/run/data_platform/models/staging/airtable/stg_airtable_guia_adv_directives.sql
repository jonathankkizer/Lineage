
  create or replace   view dw_dev.dev_jkizer_staging.stg_airtable_guia_adv_directives
  
  copy grants
  
  
  as (
    with parsing_data as (
    select
        airtable_id,
        airtable_data,
        run_datetime,
        "LAST MODIFIED" as last_modified,
        parse_json(airtable_data) as j
    from source_prod.airtable.src_airtable_guia_advance_directives
),

type_conversion as (
    select
        airtable_id,
        run_datetime::datetime as run_datetime,
        last_modified,

        -- string fields
        j:"Stage"::string as adv_directive_stage,
        j:"Status"::string as adv_directive_status,
        try_to_boolean(j:"Resolved?"::string) as is_resolved,

        -- dates / timestamps
        try_to_date(j:"Due Date"[0]::string) as due_date,
        try_to_timestamp_tz(j:"Request Date"[0]::string) as request_datetime,
        try_to_timestamp_tz(j:"Last Modified"::string) as last_modified_at,
        try_to_timestamp_tz(j:"Stage last modified at"::string) as stage_last_modified_at,
        try_to_timestamp_tz(j:"Resolved at"::string) as resolved_at,

        -- array fields
        j:"Patient Name"[0]::string as patient_name,
        j:"Patients (LINK)"[0]::string as patient_link_id,
        j:"Task Master (LINK)"[0]::string as task_master_link_id,
        j:"Workflow Type"[0]::string as workflow_type,
        j:"Requestor Notes"[0]::string as requestor_notes,
        j:"Task Name"::string as task_name,
        j:"Interface Warp Link"::string as interface_warp_link,

        j:"is_active_assignment (from Patients (LINK))"[0]::string as is_active_assignment,
        j:"elation_id (from Patients (LINK))"[0]::string as elation_id,
        j:"elation_patient_url (from Patients (LINK))"[0]::string as elation_patient_url,
        j:"location_name (from Patients (LINK))"[0]::string as location_name,
        try_to_date(j:"next_careteam_appt_date (from Patients (LINK))"[0]::string) as next_careteam_appt_date,
        try_to_date(j:"next_pcp_appt_date (from Patients (LINK))"[0]::string) as next_pcp_appt_date,
        j:"provider_name (from Patients (LINK))"[0]::string as provider_name,
        j:"high_risk_patient (from Patients (LINK))"[0]::string as high_risk_patient,

        -- ACP-specific fields
        try_to_date(j:"Date of ACP Education"::string) as date_of_acp_education,
        try_to_boolean(j:"Done"::string) as is_done,
        array_to_string(j:"Type of Assistance Given"::array, ', ') as type_of_assistance_given,
        array_to_string(j:"Forms Completed"::array, ', ') as forms_completed,
        try_to_boolean(j:"Forms uploaded to Elation chart?"::string) as forms_uploaded_to_elation,
        try_to_boolean(j:"Is Patient interested/willing to complete ACP forms?"::string) as is_patient_willing_to_complete_acp,
        try_to_boolean(j:"Patient tag updated to show DNR form on File?"::string) as is_patient_tag_updated_dnr,
        j:"Reason patient declined assistance with filling forms"::string as reason_patient_declined,
        j:"Notes"::string as notes,
        j:"🧭 Compas Note"::string as compas_note,
        j:"Attachments"::string as attachments,
        j:"⚠️Delay Reason"::string as delay_reason,

        -- nested objects
        j:"Last modified by":"name"::string as last_modified_by_name,
        j:"Last modified by":"id"::string as last_modified_by_id,
        j:"Last modified by":"email"::string as last_modified_by_email,

        j:"Stage last modified by":"name"::string as stage_last_modified_by_name,
        j:"Stage last modified by":"id"::string as stage_last_modified_by_id,
        j:"Stage last modified by":"email"::string as stage_last_modified_by_email,

        j:"Resolved by":"name"::string as resolved_by_name,
        j:"Resolved by":"id"::string as resolved_by_id,
        j:"Resolved by":"email"::string as resolved_by_email
    from parsing_data
)

select
    airtable_id,
    row_number() over (partition by airtable_id order by last_modified_at desc) as snapshot_rank,
    run_datetime,
    last_modified,
    adv_directive_stage,
    adv_directive_status,
    is_resolved,
    is_done,
    due_date,
    request_datetime,
    last_modified_at,
    stage_last_modified_at,
    resolved_at,
    patient_name,
    patient_link_id,
    task_master_link_id,
    task_name,
    interface_warp_link,
    workflow_type,
    requestor_notes,
    type_of_assistance_given,
    forms_completed,
    date_of_acp_education,
    forms_uploaded_to_elation,
    is_patient_willing_to_complete_acp,
    is_patient_tag_updated_dnr,
    reason_patient_declined,
    notes,
    compas_note,
    attachments,
    delay_reason,
    high_risk_patient,
    is_active_assignment,
    elation_id,
    elation_patient_url,
    location_name,
    next_careteam_appt_date,
    next_pcp_appt_date,
    provider_name,
    last_modified_by_name,
    last_modified_by_id,
    last_modified_by_email,
    stage_last_modified_by_name,
    stage_last_modified_by_id,
    stage_last_modified_by_email,
    resolved_by_name,
    resolved_by_id,
    resolved_by_email
from type_conversion
  );

