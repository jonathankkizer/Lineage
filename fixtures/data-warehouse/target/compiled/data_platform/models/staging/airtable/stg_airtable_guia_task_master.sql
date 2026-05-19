with parsing_data as (
    select
        airtable_id,
        run_datetime,
        "LAST MODIFIED" as last_modified,
        parse_json(airtable_data) as j
    from source_prod.airtable.src_airtable_guia_task_master_full
),
type_conversion as (
    select
        airtable_id,
        try_to_timestamp_ntz(run_datetime) as run_datetime,
        try_to_timestamp_tz(last_modified::string) as last_modified_at,

        -- IDs
        to_varchar(try_to_number(j:"Task ID"::string, 38, 0)) as task_id,
        j:"Source Key"::string as source_key,
        j:"Suvida ID"::string as suvida_id,
        j:"task_master_integration_skey"::string as task_master_integration_skey,

        -- task attributes
        j:"Task Name"::string as task_name,
        j:"MASTER STAGE"::string as master_stage,
        j:"MASTER STATUS"::string as master_status,
        j:"MASTER INTERFACE WARP LINK"[0]::string as master_interface_warp_link,
        j:"MASTER COMPAS NOTE"[0]::string as master_compas_note,
        j:"WarpButton":"url"::string as warp_button,
        j:"Active Owner Formula"::string as active_owner_formula,
        j:"📍 Active Owner":"name"::string as active_owner,
        j:"⚠ Overdue"::string as is_overdue,
        j:"Overdue Context"::string as overdue_context,
        try_to_number(j:"Task Age (# Days)"::string) as task_age_days,
        j:"📝 Quality Request - Gap Type"::string as quality_request_gap_type,
        j:"📝 Quality Request - Help Needed"::string as quality_request_help_needed,
        j:"Requestor Notes"::string as requestor_notes,
        j:"MASTER DELAY REASON"::string as master_delay_reason,
        j:"Callback Request - Requestor"::string as callback_request_requestor,
        j:"📝 Form Intake - Requestor"::string as form_intake_requestor,
        j:"📝 CC Callback - Patient Request Type"::string as cc_callback_patient_request_type,
        try_to_date(j:"📝 TOC HV Request - Discharge Date"::string) as toc_hv_request_discharge_date,
        j:"📝 TOC HV Request - Med Rec Needed?"::string as toc_hv_request_med_rec_needed,
        j:"📝 TOC HV Request - Discharge Paperwork Needed?"::string as toc_hv_request_discharge_paperwork_needed,
        j:"📝 Rx Request - Rx Name & Dosage"::string as rx_request_rx_name_dosage,
        j:"📝 Rx Request - Manufacturer Name"::string as rx_request_manufacturer_name,
        j:"📝 Rx Request - Priority"::string as rx_request_priority,
        j:"📝 SDOH Intervention Request - Category"::string as sdoh_intervention_request_category,

        -- dates / timestamps
        try_to_date(j:"Due Date"::string) as due_date,
        try_to_timestamp_tz(j:"Request Date"::string) as request_datetime,
        try_to_timestamp_tz(j:"Created"::string) as created_at,
        try_to_timestamp_tz(j:"Last Modified"::string) as airtable_last_modified_at,

        -- created / last modified by
        j:"Created by":"id"::string as created_by_id,
        j:"Created by":"email"::string as created_by_email,
        j:"Created by":"name"::string as created_by_name,
        j:"Last Modified By":"id"::string as last_modified_by_id,
        j:"Last Modified By":"email"::string as last_modified_by_email,
        j:"Last Modified By":"name"::string as last_modified_by_name,

        -- links / lookups (arrays)
        j:"Patient (LINK)"[0]::string as patient_link_id,
        j:"Patient Link Record ID"::string as patient_link_record_id,
        j:"Patient Name"[0]::string as patient_name,

        j:"Ingestion Mapping"[0]::string as ingestion_mapping_id,
        j:"Workflow Table (from Ingestion Mapping)"[0]::string as workflow_table,
        j:"Workflow Type (from Ingestion Mapping)"[0]::string as workflow_type,
        j:"Source Name (from Ingestion Mapping)"[0]::string as source_name,
        j:"Urgency (from Ingestion Mapping)"[0]::string as urgency,
        try_to_number(j:"SLA Target (Days) (from Ingestion Mapping)"[0]::string) as sla_target_days,

        -- workflow record links
        j:"Advance Directives (LINK)"[0]::string as advance_directives_link_id,
        j:"Home Visits (LINK)"[0]::string as home_visits_link_id,
        j:"Other (LINK)"[0]::string as other_link_id,
        j:"Patient Outreach (LINK)"[0]::string as patient_outreach_link_id,
        j:"Quality Gaps (LINK)"[0]::string as quality_gaps_link_id,
        j:"Safety (LINK)"[0]::string as safety_link_id,
        j:"SDOH (Link)"[0]::string as sdoh_link_id,
        j:"Social (LINK)"[0]::string as social_link_id,

        -- denormalized stage / status lookups from linked workflow tables
        j:"Stage (from Advance Directives (LINK))"[0]::string as adv_directives_stage,
        j:"Status (from Advance Directives (LINK))"[0]::string as adv_directives_status,
        j:"Stage last modified by (from Advance Directives (LINK))"[0]:"name"::string as adv_directives_stage_last_modified_by,
        j:"Interface Warp Link (from Advance Directives (LINK))"[0]::string as adv_directives_interface_warp_link,
        j:"🧭 Compas Note (from Advance Directives (LINK))"[0]::string as compas_note_adv_directives,

        j:"Stage (from Home Visits (LINK))"[0]::string as home_visits_stage,
        j:"Status (from Home Visits (LINK))"[0]::string as home_visits_status,
        j:"Stage Last modified by (from Home Visits (LINK))"[0]:"name"::string as home_visits_stage_last_modified_by,
        j:"Interface Warp Link (from Home Visits (LINK))"[0]::string as home_visits_interface_warp_link,
        j:"🧭 Compas Note (from Home Visits (LINK))"[0]::string as compas_note_home_visits,

        j:"Stage (from Other (LINK))"[0]::string as other_stage,
        j:"Status (from Other (LINK))"[0]::string as other_status,
        j:"Stage last modified by (from Other (LINK))"[0]:"name"::string as other_stage_last_modified_by,
        j:"Interface Warp Link (from Other (LINK))"[0]::string as other_interface_warp_link,

        j:"Stage (from Patient Outreach (LINK))"[0]::string as patient_outreach_stage,
        j:"Status (from Patient Outreach (LINK))"[0]::string as patient_outreach_status,
        j:"Stage last modified by (from Patient Outreach (LINK))"[0]:"name"::string as patient_outreach_stage_last_modified_by,
        j:"Interface Warp Link (from Patient Outreach (LINK))"[0]::string as patient_outreach_interface_warp_link,
        j:"🧭 Compas Note (from Patient Outreach (LINK))"[0]::string as compas_note_patient_outreach,

        j:"Stage (from Quality Gaps (LINK))"[0]::string as quality_gaps_stage,
        j:"Status (from Quality Gaps (LINK))"[0]::string as quality_gaps_status,
        j:"Stage last modified by (from Quality Gaps (LINK))"[0]:"name"::string as quality_gaps_stage_last_modified_by,
        j:"Interface Warp Link (from Quality Gaps (LINK))"[0]::string as quality_gaps_interface_warp_link,
        j:"🧭 Compas Note (from Quality Gaps (LINK))"[0]::string as compas_note_quality_gaps,

        j:"Stage (from Safety (LINK))"[0]::string as safety_stage,
        j:"Status (from Safety (LINK))"[0]::string as safety_status,
        j:"Stage last modified by (from Safety (LINK))"[0]:"name"::string as safety_stage_last_modified_by,
        j:"Interface Warp Link (from Safety (LINK))"[0]::string as safety_interface_warp_link,
        j:"🧭 Compas Note (from Safety (LINK))"[0]::string as compas_note_safety,

        j:"Stage (from SDOH (Link))"[0]::string as sdoh_stage,
        j:"Status (from SDOH (Link))"[0]::string as sdoh_status,
        j:"Stage Last Modified By (from SDOH (Link))"[0]:"name"::string as sdoh_stage_last_modified_by,
        j:"Interface Warp Link (from SDOH (Link))"[0]::string as sdoh_interface_warp_link,
        j:"🧭 Compas Note (from SDOH (Link))"[0]::string as compas_note_sdoh,

        j:"Stage (from Social (LINK))"[0]::string as social_stage,
        j:"Status (from Social (LINK))"[0]::string as social_status,
        j:"Stage last modified by (from Social (LINK))"[0]:"name"::string as social_stage_last_modified_by,
        j:"Interface Warp Link (from Social (LINK))"[0]::string as social_interface_warp_link,
        j:"🧭 Compas Note (from Social (LINK))"[0]::string as compas_note_social,

        -- denormalized delay reason lookups from linked workflow tables
        j:"Delay Reason (from Safety (LINK))"[0]::string as delay_reason_safety,
        j:"Delay Reason (from Advance Directives (LINK))"[0]::string as delay_reason_adv_directives,
        j:"Delay Reason (from Social (LINK))"[0]::string as delay_reason_social,
        j:"Delay Reason (from Quality Gaps (LINK))"[0]::string as delay_reason_quality_gaps,
        j:"Delay Reason (from Patient Outreach (LINK))"[0]::string as delay_reason_patient_outreach,
        j:"Delay Reason (from Home Visits (LINK))"[0]::string as delay_reason_home_visits,
        j:"Delay Reason (from Other (LINK))"[0]::string as delay_reason_other,
        j:"Delay Reason (from SDOH (LINK))"[0]::string as delay_reason_sdoh,

        -- resolved by (per workflow)
        j:"Resolved by (from Safety (LINK))"[0]:"name"::string as resolved_by_safety,
        j:"Resolved by (from Advance Directives (LINK))"[0]:"name"::string as resolved_by_adv_directives,
        j:"Resolved by (from Social (LINK))"[0]:"name"::string as resolved_by_social,
        j:"Resolved by (from Quality Gaps (LINK))"[0]:"name"::string as resolved_by_quality_gaps,
        j:"Resolved by (from Patient Outreach (LINK))"[0]:"name"::string as resolved_by_patient_outreach,
        j:"Resolved by (from Home Visits (LINK))"[0]:"name"::string as resolved_by_home_visits,
        j:"Resolved by (from Other (LINK))"[0]:"name"::string as resolved_by_other,
        j:"Resolved by (from SDOH (Link))"[0]:"name"::string as resolved_by_sdoh,
        j:"Resolved by Formula"::string as resolved_by_formula,
        j:"📍 Resolved By":"name"::string as resolved_by,

        -- patient lookups
        j:"elation_patient_url (from Patient (LINK))"[0]::string as elation_patient_url,
        j:"is_active_assignment (from Patient (LINK))"[0]::string as is_active_assignment,
        j:"location_name (from Patient (LINK))"[0]::string as location_name,
        j:"provider_name (from Patient (LINK))"[0]::string as provider_name,
        j:"suvida_id (from Patient (LINK))"[0]::string as suvida_id_from_patient_link,
        j:"suvida_id_master_lookup"[0]::string as suvida_id_master_lookup,
        j:"High-Risk? (from Patient (LINK))"[0]::string as high_risk_patient,
        j:"elation_id (From Patient (LINK))"[0]::string as elation_id,
        try_to_date(j:"next_pcp_appt_date (from Patient (LINK))"[0]::string) as next_pcp_appt_date,
        try_to_date(j:"Next_careteam_appt_date (Patient (LINK))"[0]::string) as next_careteam_appt_date

    from parsing_data
),

task_name_split as (
    select
        *,
        split(task_name, '|') as split_data
    from type_conversion
)

select
    airtable_id,
    row_number() over (partition by airtable_id order by last_modified_at desc) as snapshot_rank,
    run_datetime,
    last_modified_at,

    task_master_integration_skey,
    task_id,
    source_key,

    -- canonical identifiers
    suvida_id,
    patient_link_id,
    patient_link_record_id,
    patient_name,

    -- task fields
    task_name,
    master_stage,
    master_status,
    master_interface_warp_link,
    master_compas_note,
    warp_button,
    active_owner_formula,
    active_owner,
    is_overdue,
    overdue_context,
    task_age_days,
    quality_request_gap_type,
    quality_request_help_needed,
    requestor_notes,
    master_delay_reason,
    callback_request_requestor,
    form_intake_requestor,
    cc_callback_patient_request_type,
    toc_hv_request_discharge_date,
    toc_hv_request_med_rec_needed,
    toc_hv_request_discharge_paperwork_needed,
    rx_request_rx_name_dosage,
    rx_request_manufacturer_name,
    rx_request_priority,
    sdoh_intervention_request_category,
    due_date,
    request_datetime,
    created_at,
    airtable_last_modified_at,
    created_by_id,
    created_by_email,
    created_by_name,
    last_modified_by_id,
    last_modified_by_email,
    last_modified_by_name,

    -- derived fields from task_name pattern: "Patient | Task Type | YYYY-MM-DD"
    trim(split_data[0]::string) as task_patient_name,
    trim(split_data[1]::string) as task_type,
    case when array_size(split_data) >= 3 then try_to_date(trim(split_data[2]::string)) end as task_date,

    -- ingestion mapping metadata
    ingestion_mapping_id,
    workflow_table,
    workflow_type,
    source_name,
    urgency,
    sla_target_days,

    -- workflow record links
    advance_directives_link_id,
    home_visits_link_id,
    other_link_id,
    patient_outreach_link_id,
    quality_gaps_link_id,
    safety_link_id,
    sdoh_link_id,
    social_link_id,

    -- denormalized stage / status / compas note lookups
    adv_directives_stage,
    adv_directives_status,
    adv_directives_stage_last_modified_by,
    adv_directives_interface_warp_link,
    compas_note_adv_directives,
    home_visits_stage,
    home_visits_status,
    home_visits_stage_last_modified_by,
    home_visits_interface_warp_link,
    compas_note_home_visits,
    other_stage,
    other_status,
    other_stage_last_modified_by,
    other_interface_warp_link,
    patient_outreach_stage,
    patient_outreach_status,
    patient_outreach_stage_last_modified_by,
    patient_outreach_interface_warp_link,
    compas_note_patient_outreach,
    quality_gaps_stage,
    quality_gaps_status,
    quality_gaps_stage_last_modified_by,
    quality_gaps_interface_warp_link,
    compas_note_quality_gaps,
    safety_stage,
    safety_status,
    safety_stage_last_modified_by,
    safety_interface_warp_link,
    compas_note_safety,
    sdoh_stage,
    sdoh_status,
    sdoh_stage_last_modified_by,
    sdoh_interface_warp_link,
    compas_note_sdoh,
    social_stage,
    social_status,
    social_stage_last_modified_by,
    social_interface_warp_link,
    compas_note_social,

    -- denormalized delay reason lookups
    delay_reason_safety,
    delay_reason_adv_directives,
    delay_reason_social,
    delay_reason_quality_gaps,
    delay_reason_patient_outreach,
    delay_reason_home_visits,
    delay_reason_other,
    delay_reason_sdoh,

    -- resolved by
    resolved_by_safety,
    resolved_by_adv_directives,
    resolved_by_social,
    resolved_by_quality_gaps,
    resolved_by_patient_outreach,
    resolved_by_home_visits,
    resolved_by_other,
    resolved_by_sdoh,
    resolved_by_formula,
    resolved_by,

    -- patient lookups
    elation_patient_url,
    is_active_assignment,
    location_name,
    provider_name,
    suvida_id_from_patient_link,
    suvida_id_master_lookup,
    high_risk_patient,
    elation_id,
    next_pcp_appt_date,
    next_careteam_appt_date

from task_name_split