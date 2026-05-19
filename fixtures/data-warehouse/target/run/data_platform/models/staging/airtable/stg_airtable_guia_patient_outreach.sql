
  create or replace   view dw_dev.dev_jkizer_staging.stg_airtable_guia_patient_outreach
  
  copy grants
  
  
  as (
    with parsing_data as (
    select
        airtable_id,
        run_datetime,
        "LAST MODIFIED",
        airtable_data,
        parse_json(airtable_data) as j
    from source_prod.airtable.src_airtable_guia_patient_outreach
),

type_conversion as (
    select
        airtable_id,
        run_datetime::datetime as run_datetime,
        "LAST MODIFIED" as last_modified,

        j:"Last Modified By":"name"::string as last_modified_by_name,
        j:"Last Modified By":"id"::string as last_modified_by_id,
        j:"Last Modified By":"email"::string as last_modified_by_email,

        try_to_date(j:"Due Date"[0]::string) as due_date,
        j:"Interface Warp Link":: string as interface_warp_link,

        j:"Stage last modified by":"email"::string as stage_last_modified_by_email,
        j:"Stage last modified by":"name"::string as stage_last_modified_by_name,
        j:"Stage last modified by":"id"::string as stage_last_modified_by_id,
        try_to_timestamp_tz(j:"Stage last modified at"::string) as stage_last_modified_at,

        j:"Patient (LINK)"[0]::string as patient_link_id,
        j:"Patient Name"[0]::string as patient_name,
        try_to_timestamp_tz(j:"Request Date"[0]::string) as request_datetime,
        j:"Requestor Notes"[0]::string as requestor_notes,

        j:"Stage"::string as outreach_stage,
        j:"Status"::string as outreach_status,
        j:"Task Master (LINK)"[0]::string as task_master_link_id,
        j:"Task Name"::string as task_name,
        j:"Workflow Type"[0]::string as workflow_type,

        -- task master lookups
        j:"Callback Request - Requestor (from Task Master (LINK))"[0]::string as callback_request_requestor,

        -- patient lookups
        j:"high_risk_patient (from Patient (LINK))"[0]::string as high_risk_patient,
        j:"elation_patient_url (from Patient (LINK))"[0]::string as elation_patient_url,
        j:"provider_name (from Patient (LINK))"[0]::string as provider_name,
        j:"location_name (from Patient (LINK))"[0]::string as location_name,
        try_to_date(j:"next_pcp_appt_date (from Patient (LINK))"[0]::string) as next_pcp_appt_date,
        try_to_date(j:"next_careteam_appt_date (from Patient (LINK))"[0]::string) as next_careteam_appt_date,
        j:"phone (from Patient (LINK))"[0]::string as phone,
        j:"phone_type (from Patient (LINK))"[0]::string as phone_type,
        j:"secondary_phone (from Patient (LINK))"[0]::string as secondary_phone,
        j:"secondary_phone_type (from Patient (LINK))"[0]::string as secondary_phone_type,
        j:"is_active_assignment (from Patient (LINK))"[0]::string as is_active_assignment,

        -- outreach tracking
        j:"Notes"::string as notes,
        j:"🧭 Compas Note"::string as compas_note,
        j:"Attachments"::string as attachments,
        j:"⚠️Delay Reason"::string as delay_reason,
        j:"Outreach 1"::string as outreach_1,
        try_to_date(j:"Outreach 1 Date"::string) as outreach_1_date,
        j:"Outreach 2"::string as outreach_2,
        try_to_date(j:"Outreach 2 Date"::string) as outreach_2_date,
        j:"Patient Request Type"::string as patient_request_type,
        j:"Request Routing"::string as request_routing,
        j:"Request Type"::string as request_type,

        -- resolution
        try_to_boolean(j:"Resolved?"::string) as is_resolved,
        try_to_timestamp_tz(j:"Resolved at"::string) as resolved_at,
        j:"Resolved by":"id"::string as resolved_by_id,
        j:"Resolved by":"email"::string as resolved_by_email,
        j:"Resolved by":"name"::string as resolved_by_name

    from parsing_data
)

select
    airtable_id,
    row_number() over (partition by airtable_id order by last_modified desc) as snapshot_rank,
    run_datetime,
    last_modified,
    patient_link_id,
    patient_name,
    outreach_stage,
    outreach_status,
    due_date,
    request_datetime,
    requestor_notes,
    interface_warp_link,
    task_master_link_id,
    task_name,
    workflow_type,
    callback_request_requestor,
    high_risk_patient,
    elation_patient_url,
    provider_name,
    location_name,
    next_pcp_appt_date,
    next_careteam_appt_date,
    phone,
    phone_type,
    secondary_phone,
    secondary_phone_type,
    is_active_assignment,
    notes,
    compas_note,
    attachments,
    delay_reason,
    outreach_1,
    outreach_1_date,
    outreach_2,
    outreach_2_date,
    patient_request_type,
    request_routing,
    request_type,
    is_resolved,
    resolved_at,
    resolved_by_id,
    resolved_by_email,
    resolved_by_name,
    last_modified_by_name,
    last_modified_by_id,
    last_modified_by_email,
    stage_last_modified_at,
    stage_last_modified_by_name,
    stage_last_modified_by_id,
    stage_last_modified_by_email
from type_conversion
  );

