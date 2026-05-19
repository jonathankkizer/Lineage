with parsing_data as (
    select
        airtable_id,
        run_datetime,
        "LAST MODIFIED" as last_modified,
        airtable_data,
        parse_json(airtable_data) as j
    from source_prod.airtable.src_airtable_guia_other
),

type_conversion as (
    select
        airtable_id,
        run_datetime::datetime as run_datetime,
        last_modified,

        j:"Stage"::string as other_stage,
        j:"Status"::string as other_status,

        try_to_date(j:"Due Date"[0]::string) as due_date,
        try_to_timestamp_tz(j:"Request Date"[0]::string) as request_datetime,
        j:"Requestor Notes"[0]::string as requestor_notes,
        j:"Task Name"::string as task_name,
        j:"Task"::string as task,
        j:"Task Description"::string as task_description,
        j:"Notes"::string as notes,
        j:"🧭 Compas Note"::string as compas_note,
        j:"Attachments"::string as attachments,
        j:"⚠️Delay Reason"::string as delay_reason,
        j:"Interface Warp Link"::string as interface_warp_link,

        j:"Patient (LINK)"[0]::string as patient_link_id,
        j:"Patient Name"[0]::string as patient_name,
        j:"Task Master (LINK)"[0]::string as task_master_link_id,
        j:"Workflow Type"[0]::string as workflow_type,

        -- stage tracking
        try_to_timestamp_tz(j:"Stage last modified at"::string) as stage_last_modified_at,
        j:"Stage last modified by":"id"::string as stage_last_modified_by_id,
        j:"Stage last modified by":"email"::string as stage_last_modified_by_email,
        j:"Stage last modified by":"name"::string as stage_last_modified_by_name,

        -- resolution
        try_to_boolean(j:"Resolved?"::string) as is_resolved,
        try_to_timestamp_tz(j:"Resolved at"::string) as resolved_at,
        j:"Resolved by":"id"::string as resolved_by_id,
        j:"Resolved by":"email"::string as resolved_by_email,
        j:"Resolved by":"name"::string as resolved_by_name,

        -- last modified
        j:"Last Modified By":"id"::string as last_modified_by_id,
        j:"Last Modified By":"email"::string as last_modified_by_email,
        j:"Last Modified By":"name"::string as last_modified_by_name,

        -- patient lookups
        j:"is_active_assignment (from Patient (LINK))"[0]::string as is_active_assignment,
        j:"elation_patient_url (from Patient (LINK))"[0]::string as elation_patient_url,
        j:"location_name (from Patient (LINK))"[0]::string as location_name,
        try_to_date(j:"next_careteam_appt_date (from Patient (LINK))"[0]::string) as next_careteam_appt_date,
        try_to_date(j:"next_pcp_appt_date (from Patient (LINK))"[0]::string) as next_pcp_appt_date,
        j:"provider_name (from Patient (LINK))"[0]::string as provider_name
    from parsing_data
)

select
    airtable_id,
    row_number() over (partition by airtable_id order by last_modified desc) as snapshot_rank,
    run_datetime,
    last_modified,
    other_stage,
    other_status,
    due_date,
    request_datetime,
    requestor_notes,
    task_name,
    task,
    task_description,
    notes,
    compas_note,
    attachments,
    delay_reason,
    interface_warp_link,
    is_resolved,
    patient_link_id,
    patient_name,
    task_master_link_id,
    workflow_type,
    stage_last_modified_at,
    stage_last_modified_by_id,
    stage_last_modified_by_email,
    stage_last_modified_by_name,
    resolved_at,
    resolved_by_id,
    resolved_by_email,
    resolved_by_name,
    last_modified_by_id,
    last_modified_by_email,
    last_modified_by_name,
    is_active_assignment,
    elation_patient_url,
    location_name,
    next_careteam_appt_date,
    next_pcp_appt_date,
    provider_name
from type_conversion