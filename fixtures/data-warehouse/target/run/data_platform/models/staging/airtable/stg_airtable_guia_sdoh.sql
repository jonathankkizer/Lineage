
  create or replace   view dw_dev.dev_jkizer_staging.stg_airtable_guia_sdoh
  
  copy grants
  
  
  as (
    with parsing_data as (
    select
        airtable_id,
        run_datetime,
        "LAST MODIFIED" as last_modified,
        airtable_data,
        parse_json(airtable_data) as j
    from source_prod.airtable.src_airtable_guia_sdoh
),

type_conversion as (
    select
        airtable_id,
        run_datetime::datetime as run_datetime,
        last_modified,

        -- simple string fields
        j:"Stage"::string as sdoh_stage,
        j:"Status"::string as sdoh_status,
        j:"Name"::string as task_name,
        j:"Interface Warp Link"::string as interface_warp_link,

        -- dates / timestamps
        try_to_timestamp_tz(j:"Request Date"[0]::string) as request_datetime,
        try_to_date(j:"Due Date"[0]::string) as due_date,

        -- arrays (first element)
        j:"Patients (Link)"[0]::string as patient_link_id,
        j:"Patient Name"[0]::string as patient_name,
        j:"Task Master (Link)"[0]::string as task_master_link_id,
        j:"📝 SDOH Intervention Request - Category (from Task Master (Link))"[0]::string as tm_sdoh_intervention_request_category,
        j:"Workflow Type"[0]::string as workflow_type,
        j:"Requestor Notes"[0]::string as requestor_notes,

        -- SDoh specific
        j:"Intervention Description"::string as intervention_description,
        j:"Intervention SDoH Category"::string as intervention_sdoh_category,
        try_to_boolean(j:"Was Elation z-code problem list information updated to reflect support provided?"::string) as is_elation_zcode_updated,
        j:"Notes"::string as notes,
        j:"🧭 Compas Note"::string as compas_note,
        j:"Attachments"::string as attachments,

        j:"⚠️Delay Reason"::string as delay_reason,

        -- resolution
        try_to_boolean(j:"Resolved?"::string) as is_resolved,
        try_to_timestamp_tz(j:"Resolved at"::string) as resolved_at,
        j:"Resolved by":"id"::string as resolved_by_id,
        j:"Resolved by":"email"::string as resolved_by_email,
        j:"Resolved by":"name"::string as resolved_by_name,

        -- patient lookups
        j:"is_active_assignment (from Patients (Link))"[0]::string as is_active_assignment,
        j:"location_name (from Patients (Link))"[0]::string as location_name,
        j:"provider_name (from Patients (Link))"[0]::string as provider_name,
        j:"elation_patient_url (from Patients (Link))"[0]::string as elation_patient_url,
        j:"elation_id (from Patients (Link))"[0]::string as elation_id,
        j:"dual_status (from Patients (Link))"[0]::string as dual_status,
        j:"high_risk_patient (from Patients (Link))"[0]::string as high_risk_patient,
        try_to_date(j:"next_pcp_appt_date (from Patients (Link))"[0]::string) as next_pcp_appt_date,
        try_to_date(j:"next_careteam_appt_date (from Patients (Link))"[0]::string) as next_careteam_appt_date,

        -- patient alert lookups: ✅ = secure (0), red alert emoji = insecure (1), null = 0
        case when j:"Falls Alert (from Patients (Link))"[0]::string != '✅' then 1 else 0 end as falls_alert,
        case when j:"Financial Alert (from Patients (Link))"[0]::string != '✅' then 1 else 0 end as financial_alert,
        case when j:"Food Alert (from Patients (Link))"[0]::string != '✅' then 1 else 0 end as food_alert,
        case when j:"Housing Alert (from Patients (Link))"[0]::string != '✅' then 1 else 0 end as housing_alert,
        case when j:"Transportation Alert (from Patients (Link))"[0]::string != '✅' then 1 else 0 end as transportation_alert,

        -- nested objects: last modified by
        j:"Last Modified By":"id"::string as last_modified_by_id,
        j:"Last Modified By":"email"::string as last_modified_by_email,
        j:"Last Modified By":"name"::string as last_modified_by_name,

        -- stage audit
        try_to_timestamp_tz(j:"Stage Last Modified at"::string) as stage_last_modified_at,
        j:"Stage Last Modified By":"id"::string as stage_last_modified_by_id,
        j:"Stage Last Modified By":"email"::string as stage_last_modified_by_email,
        j:"Stage Last Modified By":"name"::string as stage_last_modified_by_name

    from parsing_data
)

select
    airtable_id,
    row_number() over (partition by airtable_id order by last_modified desc) as snapshot_rank,
    run_datetime,
    last_modified,
    sdoh_stage,
    sdoh_status,
    task_name,
    interface_warp_link,
    request_datetime,
    due_date,
    patient_link_id,
    patient_name,
    task_master_link_id,
    tm_sdoh_intervention_request_category,
    workflow_type,
    requestor_notes,
    intervention_description,
    intervention_sdoh_category,
    is_elation_zcode_updated,
    notes,
    compas_note,
    attachments,
    delay_reason,
    is_resolved,
    resolved_at,
    resolved_by_id,
    resolved_by_email,
    resolved_by_name,
    is_active_assignment,
    location_name,
    provider_name,
    elation_patient_url,
    elation_id,
    dual_status,
    high_risk_patient,
    next_pcp_appt_date,
    next_careteam_appt_date,
    falls_alert,
    financial_alert,
    food_alert,
    housing_alert,
    transportation_alert,
    last_modified_by_id,
    last_modified_by_email,
    last_modified_by_name,
    stage_last_modified_at,
    stage_last_modified_by_id,
    stage_last_modified_by_email,
    stage_last_modified_by_name
from type_conversion
  );

