with parsing_data as (
    select
        airtable_id,
        run_datetime,
        "LAST MODIFIED" as last_modified,
        airtable_data,
        parse_json(airtable_data) as j
    from source_prod.airtable.src_airtable_guia_quality_gaps
),

type_conversion as (
    select
        airtable_id,
        run_datetime::datetime as run_datetime,
        last_modified,

        -- simple string fields
        j:"Stage"::string as gap_stage,
        j:"Status"::string as gap_status,

        -- dates / timestamps
        try_to_timestamp_tz(j:"Created"::string) as created_at,
        try_to_timestamp_tz(j:"Request Date"[0]::string) as request_datetime,
        try_to_date(j:"Due Date"[0]::string) as due_date,

        -- arrays (first element)
        j:"Patient (LINK)"[0]::string as patient_link_id,
        j:"Patient Name"[0]::string as patient_name,
        j:"Task Master (LINK)"[0]::string as task_master_link_id,
        j:"Workflow Type"[0]::string as workflow_type,
        j:"Requestor Notes"[0]::string as requestor_notes,
        j:"Task Name"::string as task_name,
        j:"Interface Warp Link"::string as interface_warp_link,
        -- TODO: verify if "Gap Assistance Type(s)" was renamed — not visible in Airtable field display but has data; may overlap with quality_request_gap_type
        array_to_string(j:"Gap Assistance Type(s)"::array, ', ') as gap_assistance_types,
        j:"Quality Request - Gap Type (from Task Master (LINK))"[0]::string as quality_request_gap_type,
        j:"Quality Request - Help Needed (from Task Master (LINK))"[0]::string as quality_request_help_needed,
        j:"Created by (from Task Master (LINK))"[0]:"id"::string as task_master_created_by_id,
        j:"Created by (from Task Master (LINK))"[0]:"email"::string as task_master_created_by_email,
        j:"Created by (from Task Master (LINK))"[0]:"name"::string as task_master_created_by_name,
        j:"Attachments"::string as attachments,
        j:"Notes"::string as notes,
        j:"🧭 Compas Note"::string as compas_note,
        j:"⚠️Delay Reason"::string as delay_reason,

        -- outreach tracking
        -- outreach tracking
        j:"Outreach 1"::string as outreach_1,
        j:"Outreach 2"::string as outreach_2,
        j:"Outreach 3"::string as outreach_3,
        try_to_date(j:"Outreach1 Date"::string) as outreach_1_date,
        try_to_date(j:"Outreach 2 Date"::string) as outreach_2_date,
        try_to_date(j:"Outreach 3 Date"::string) as outreach_3_date,
        try_to_timestamp_tz(j:"Outreach 2 Outcome Last Modified"::string) as outreach_2_outcome_last_modified,
        j:"Contact Status"::string as contact_status,

        -- disposition / outcome
        j:"Specialist Contact Information"::string as specialist_contact_information,
        j:"Outcome"::string as outcome,
        j:"Final Disposition"::string as final_disposition,
        j:"Reason for Decline"::string as reason_for_decline,
        j:"Reason Unable to Schedule (If Patient Wants Service but Couldn't Schedule)"::string as reason_unable_to_schedule,
        try_to_date(j:"Appointment Date"::string) as appointment_date,
        try_to_date(j:"Kit Return Date"::string) as kit_return_date,

        -- patient lookups
        j:"location_name (from Patient (LINK))"[0]::string as location_name,
        j:"provider_name (from Patient (LINK))"[0]::string as provider_name,
        j:"elation_patient_url (from Patient (LINK))"[0]::string as elation_patient_url,
        j:"is_active_assignment (from Patient (LINK))"[0]::string as is_active_assignment,
        j:"high_risk_patient (from Patient (LINK))"[0]::string as high_risk_patient,
        try_to_date(j:"last_pcp_appt_date (from Patient (LINK))"[0]::string) as last_pcp_appt_date,
        try_to_date(j:"next_pcp_appt_date (from Patient (LINK))"[0]::string) as next_pcp_appt_date,
        j:"phone (from Patient (LINK))"[0]::string as phone,
        j:"secondary_phone (from Patient (LINK))"[0]::string as secondary_phone,

        -- nested objects
        j:"Created By":"id"::string as created_by_id,
        j:"Created By":"email"::string as created_by_email,
        j:"Created By":"name"::string as created_by_name,

        j:"Last Modified By":"id"::string as last_modified_by_id,
        j:"Last Modified By":"email"::string as last_modified_by_email,
        j:"Last Modified By":"name"::string as last_modified_by_name,

        try_to_timestamp_tz(j:"Stage last modified at"::string) as stage_last_modified_at,
        j:"Stage last modified by":"id"::string as stage_last_modified_by_id,
        j:"Stage last modified by":"email"::string as stage_last_modified_by_email,
        j:"Stage last modified by":"name"::string as stage_last_modified_by_name,

        -- resolution
        j:"Resolved?"::boolean as is_resolved,
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
    gap_stage,
    gap_status,
    created_at,
    request_datetime,
    due_date,
    patient_link_id,
    patient_name,
    task_master_link_id,
    task_name,
    interface_warp_link,
    workflow_type,
    requestor_notes,
    gap_assistance_types,
    quality_request_gap_type,
    quality_request_help_needed,
    task_master_created_by_id,
    task_master_created_by_email,
    task_master_created_by_name,
    attachments,
    notes,
    compas_note,
    delay_reason,
    outreach_1,
    outreach_2,
    outreach_3,
    outreach_1_date,
    outreach_2_date,
    outreach_3_date,
    outreach_2_outcome_last_modified,
    contact_status,
    specialist_contact_information,
    outcome,
    final_disposition,
    reason_for_decline,
    reason_unable_to_schedule,
    appointment_date,
    kit_return_date,
    location_name,
    provider_name,
    elation_patient_url,
    is_active_assignment,
    high_risk_patient,
    last_pcp_appt_date,
    next_pcp_appt_date,
    phone,
    secondary_phone,
    created_by_id,
    created_by_email,
    created_by_name,
    last_modified_by_id,
    last_modified_by_email,
    last_modified_by_name,
    stage_last_modified_at,
    stage_last_modified_by_id,
    stage_last_modified_by_email,
    stage_last_modified_by_name,
    is_resolved,
    resolved_at,
    resolved_by_id,
    resolved_by_email,
    resolved_by_name
from type_conversion