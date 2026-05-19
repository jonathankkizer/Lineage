with parsing_data as (
    select
        airtable_id,
        run_datetime,
        "LAST MODIFIED" as last_modified,
        airtable_data,
        parse_json(airtable_data) as j
    from source_prod.airtable.src_airtable_guia_safety
),

type_conversion as (
    select
        airtable_id,
        run_datetime::datetime as run_datetime,
        j:"Patient (LINK)"[0]::string as patient_link_id,
        j:"Patient Name"[0]::string as patient_name,

        try_to_timestamp_tz(j:"Request Date"[0]::string) as request_datetime,
        j:"Requestor Notes"[0]::string as requestor_notes,
        try_to_date(j:"Due Date"[0]::string) as due_date,

        last_modified,
        j:"Last Modified By":"id"::string as last_modified_by_id,
        j:"Last Modified By":"email"::string as last_modified_by_email,
        j:"Last Modified By":"name"::string as last_modified_by_name,

        -- stage
        j:"Stage"::string as safety_stage,
        j:"Status"::string as safety_status,
        try_to_timestamp_tz(j:"Stage last modified time"::string) as stage_last_modified_at,
        j:"Stage last modified by":"id"::string as stage_last_modified_by_id,
        j:"Stage last modified by":"email"::string as stage_last_modified_by_email,
        j:"Stage last modified by":"name"::string as stage_last_modified_by_name,

        -- tasks
        j:"Task Master (LINK)"[0]::string as task_master_link_id,
        j:"Workflow Type"[0]::string as workflow_type,
        j:"Task Name"::string as task_name,
        j:"Interface Warp Link"::string as interface_warp_link,

        -- incident details
        j:"Attachments"::string as attachments,
        coalesce(
            j:"Brief Incident Summary and Consultation Recommendations"::string,
            j:"Incident Description"::string
        ) as incident_description,
        j:"Notes"::string as notes,
        j:"🧭 Compas Note"::string as compas_note,
        try_to_boolean(j:"APS Report Filed"::string) as is_aps_report_filed,
        try_to_date(j:"Date of APS Report"::string) as date_of_aps_report,
        j:"APS Report Outcome"::string as aps_report_outcome,
        j:"Case Number #"::string as case_number,
        try_to_boolean(j:"Update the Provider and clinical team?"::string) as is_provider_team_updated,
        j:"Reason for not filing report"::string as reason_not_filing_report,
        j:"Who was consulted on this incident?"::string as who_was_consulted,
        j:"⚠️Delay Reason"::string as delay_reason,

        -- patient lookups
        j:"High-Risk? (from Patients (LINK))"[0]::string as high_risk_patient,

        -- resolution
        try_to_boolean(j:"Resolved?"::string) as is_resolved,
        try_to_date(j:"Resolved Date"::string) as resolved_date,
        j:"Resolved by":"id"::string as resolved_by_id,
        j:"Resolved by":"email"::string as resolved_by_email,
        j:"Resolved by":"name"::string as resolved_by_name,

        j:"is_active_assignment (from Patient (LINK))"[0]::string as is_active_assignment,
        j:"elation_id (from Patient (LINK))"[0]::string as elation_id,
        j:"elation_patient_url (from Patient (LINK))"[0]::string as elation_patient_url,
        j:"location_name (from Patient (LINK))"[0]::string as location_name,
        j:"provider_name (from Patient (LINK))"[0]::string as provider_name
    from parsing_data
)

select
    airtable_id,
    row_number() over (partition by airtable_id order by last_modified desc) as snapshot_rank,
    run_datetime,
    last_modified,
    patient_link_id,
    patient_name,
    request_datetime,
    requestor_notes,
    due_date,
    last_modified_by_id,
    last_modified_by_email,
    last_modified_by_name,
    safety_stage,
    safety_status,
    stage_last_modified_at,
    stage_last_modified_by_id,
    stage_last_modified_by_email,
    stage_last_modified_by_name,
    task_master_link_id,
    task_name,
    interface_warp_link,
    workflow_type,
    attachments,
    incident_description,
    notes,
    compas_note,
    is_aps_report_filed,
    date_of_aps_report,
    aps_report_outcome,
    case_number,
    is_provider_team_updated,
    reason_not_filing_report,
    who_was_consulted,
    delay_reason,
    high_risk_patient,
    is_resolved,
    resolved_date,
    resolved_by_id,
    resolved_by_email,
    resolved_by_name,
    is_active_assignment,
    elation_id,
    elation_patient_url,
    location_name,
    provider_name
from type_conversion