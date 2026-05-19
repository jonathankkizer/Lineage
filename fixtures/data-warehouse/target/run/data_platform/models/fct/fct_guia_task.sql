
  
    

create or replace transient table dw_dev.dev_jkizer.fct_guia_task
    copy grants
    
    
    as (-- Documentation: https://suvidahealthcare-data.atlassian.net/wiki/spaces/data/pages/353730566/Guia+Airtable+Integration+Documentation


with task_master as (
    select * from dw_dev.dev_jkizer_staging.stg_airtable_guia_task_master
),

social as (
    select * from dw_dev.dev_jkizer_staging.stg_airtable_guia_social
),

safety as (
    select * from dw_dev.dev_jkizer_staging.stg_airtable_guia_safety
),

adv_directives as (
    select * from dw_dev.dev_jkizer_staging.stg_airtable_guia_adv_directives
),

quality_gaps as (
    select * from dw_dev.dev_jkizer_staging.stg_airtable_guia_quality_gaps
),

home_visit as (
    select * from dw_dev.dev_jkizer_staging.stg_airtable_guia_home_visit
),

patient_outreach as (
    select * from dw_dev.dev_jkizer_staging.stg_airtable_guia_patient_outreach
),

sdoh as (
    select * from dw_dev.dev_jkizer_staging.stg_airtable_guia_sdoh
),

other as (
    select * from dw_dev.dev_jkizer_staging.stg_airtable_guia_other
),

final as (
    select
    -- identifiers
        tm.airtable_id,
        tm.snapshot_rank,
        tm.task_master_integration_skey,
        tm.task_id,
        tm.suvida_id,
        tm.patient_link_id,

        -- task metadata
        tm.task_type,
        tm.task_date,
        tm.workflow_table,
        tm.workflow_type,
        tm.source_name,
        tm.urgency,
        tm.sla_target_days,
        tm.quality_request_gap_type,
        tm.quality_request_help_needed,
        tm.master_delay_reason,
        tm.callback_request_requestor,
        tm.form_intake_requestor,
        tm.cc_callback_patient_request_type,
        tm.toc_hv_request_discharge_date as tm_toc_hv_request_discharge_date,
        tm.toc_hv_request_med_rec_needed as tm_toc_hv_request_med_rec_needed,
        tm.toc_hv_request_discharge_paperwork_needed as tm_toc_hv_request_discharge_paperwork_needed,
        tm.rx_request_rx_name_dosage,
        tm.rx_request_manufacturer_name,
        tm.rx_request_priority,
        tm.sdoh_intervention_request_category,

    -- master stage / status / compas note (task master level)
        tm.master_stage,
        tm.master_status,
        tm.master_compas_note,

    -- workflow-level stage / status (coalesced across all workflow tables)
        initcap(trim(coalesce(
            s.social_stage,
            sf.safety_stage,
            ad.adv_directive_stage,
            qg.gap_stage,
            hv.home_visit_stage,
            po.outreach_stage,
            sd.sdoh_stage,
            ot.other_stage
                ))) as workflow_stage,

        coalesce(
            s.social_status,
            sf.safety_status,
            ad.adv_directive_status,
            qg.gap_status,
            hv.home_visit_status,
            po.outreach_status,
            sd.sdoh_status,
            ot.other_status
                ) as workflow_status,

     -- dates
        tm.request_datetime as master_request_datetime,
        tm.due_date as master_due_date,
        tm.created_at as master_created_at,
        tm.last_modified_at as master_last_modified_at,

    -- workflow-specific: requestor notes (coalesced)
        coalesce(
            s.requestor_notes,
            sf.requestor_notes,
            ad.requestor_notes,
            qg.requestor_notes,
            hv.requestor_notes,
            po.requestor_notes,
            sd.requestor_notes,
            ot.requestor_notes
                ) as requestor_notes,

        -- stage audit (coalesced)
        coalesce(
            s.stage_last_modified_at,
            sf.stage_last_modified_at,
            ad.stage_last_modified_at,
            qg.stage_last_modified_at,
            hv.stage_last_modified_at,
            po.stage_last_modified_at,
            sd.stage_last_modified_at,
            ot.stage_last_modified_at
                ) as stage_last_modified_at,

        coalesce(
            s.stage_last_modified_by_name,
            sf.stage_last_modified_by_name,
            ad.stage_last_modified_by_name,
            qg.stage_last_modified_by_name,
            hv.stage_last_modified_by_name,
            po.stage_last_modified_by_name,
            sd.stage_last_modified_by_name,
            ot.stage_last_modified_by_name
                ) as stage_last_modified_by_name,

        coalesce(
            s.stage_last_modified_by_id,
            sf.stage_last_modified_by_id,
            ad.stage_last_modified_by_id,
            qg.stage_last_modified_by_id,
            hv.stage_last_modified_by_id,
            po.stage_last_modified_by_id,
            sd.stage_last_modified_by_id,
            ot.stage_last_modified_by_id
                ) as stage_last_modified_by_id,

        coalesce(
            s.stage_last_modified_by_email,
            sf.stage_last_modified_by_email,
            ad.stage_last_modified_by_email,
            qg.stage_last_modified_by_email,
            hv.stage_last_modified_by_email,
            po.stage_last_modified_by_email,
            sd.stage_last_modified_by_email,
            ot.stage_last_modified_by_email
                ) as stage_last_modified_by_email,

    -- workflow record last modified by (coalesced — only one workflow table joins per task)
        coalesce(
            s.last_modified_by_name,
            sf.last_modified_by_name,
            ad.last_modified_by_name,
            qg.last_modified_by_name,
            hv.last_modified_by_name,
            po.last_modified_by_name,
            sd.last_modified_by_name,
            ot.last_modified_by_name
                ) as workflow_last_modified_by_name,

        coalesce(
            s.last_modified_by_id,
            sf.last_modified_by_id,
            ad.last_modified_by_id,
            qg.last_modified_by_id,
            hv.last_modified_by_id,
            po.last_modified_by_id,
            sd.last_modified_by_id,
            ot.last_modified_by_id
                ) as workflow_last_modified_by_id,

        coalesce(
            s.last_modified_by_email,
            sf.last_modified_by_email,
            ad.last_modified_by_email,
            qg.last_modified_by_email,
            hv.last_modified_by_email,
            po.last_modified_by_email,
            sd.last_modified_by_email,
            ot.last_modified_by_email
                ) as workflow_last_modified_by_email,

    -- interface warp link (coalesced; task_master denormalized lookups used as fallback for po/hv/ot)
        coalesce(
            s.interface_warp_link,
            sf.interface_warp_link,
            ad.interface_warp_link,
            qg.interface_warp_link,
            hv.interface_warp_link,
            po.interface_warp_link,
            sd.interface_warp_link,
            ot.interface_warp_link,
            tm.patient_outreach_interface_warp_link,
            tm.home_visits_interface_warp_link,
            tm.other_interface_warp_link
                ) as interface_warp_link,

        s.warp_button as soc_warp_button,

    -- patient attributes denormalized onto workflow tables (coalesced)
        /*coalesce(s.high_risk_patient, sf.high_risk_patient, ad.high_risk_patient, hv.high_risk_patient, sd.high_risk_patient, po.high_risk_patient, qg.high_risk_patient) as high_risk_patient,
        coalesce(s.dual_status, sd.dual_status) as dual_status,
        coalesce(s.next_pcp_appt_date, sd.next_pcp_appt_date, qg.next_pcp_appt_date, ad.next_pcp_appt_date, hv.next_pcp_appt_date, po.next_pcp_appt_date, ot.next_pcp_appt_date) as next_pcp_appt_date,
        coalesce(s.next_careteam_appt_date, sd.next_careteam_appt_date, ad.next_careteam_appt_date, hv.next_careteam_appt_date, po.next_careteam_appt_date, ot.next_careteam_appt_date) as next_careteam_appt_date,
        coalesce(qg.is_active_assignment, hv.is_active_assignment, po.is_active_assignment) as is_active_assignment,
        coalesce(qg.phone, po.phone) as phone,
        coalesce(qg.secondary_phone, po.secondary_phone) as secondary_phone,
        po.phone_type as po_phone_type,
        po.secondary_phone_type as po_secondary_phone_type, */
        qg.last_pcp_appt_date as qg_last_pcp_appt_date,
        hv.roi_form_due_date as hv_roi_form_due_date,

        -- workflow-specific sparse columns: home visit
        hv.tm_created_by_name as hv_tm_created_by_name,
        hv.tm_created_by_id as hv_tm_created_by_id,
        hv.tm_created_by_email as hv_tm_created_by_email,
        hv.last_modified_at as hv_last_modified_at,
        hv.hv_completed_date,
        hv.hv_planned_datetime,
        hv.is_discharge_paperwork_needed as hv_is_discharge_paperwork_needed,
        hv.is_discharge_paperwork_needed_v2 as hv_is_discharge_paperwork_needed_v2,
        hv.is_home_visit_completed as hv_is_home_visit_completed,
        hv.is_discharge_date_confirmed as hv_is_discharge_date_confirmed,
        hv.medication_reconciliation_due as hv_medication_reconciliation_due,
        hv.is_medications_available as hv_is_medications_available,
        hv.medication_list_photo as hv_medication_list_photo,
        hv.discharge_summary_photo as hv_discharge_summary_photo,
        hv.signed_roi_photo as hv_signed_roi_photo,
        hv.is_roi_completed as hv_is_roi_completed,
        hv.pcp_toc_visit_outcome as hv_pcp_toc_visit_outcome,
        hv.roi_due_alert as hv_roi_due_alert,
        hv.nurse_toc_visit_outcome as hv_nurse_toc_visit_outcome,
        hv.was_patient_available as hv_was_patient_available,
        hv.has_discharge_summary as hv_has_discharge_summary,
        hv.did_call_patient as hv_did_call_patient,
        hv.did_speak_with_referring_nurse as hv_did_speak_with_referring_nurse,
        hv.needs_followup_specialist_assistance as hv_needs_followup_specialist_assistance,
        hv.toc_hv_request_discharge_date as hv_toc_hv_request_discharge_date,
        hv.toc_hv_request_med_rec_needed as hv_toc_hv_request_med_rec_needed,
        hv.toc_hv_request_discharge_paperwork_needed as hv_toc_hv_request_discharge_paperwork_needed,

    -- workflow-specific sparse columns: advance directives / ACP
        ad.last_modified_at as adv_last_modified_at,
        ad.is_done as adv_is_done,
        ad.type_of_assistance_given as adv_type_of_assistance_given,
        ad.forms_completed as adv_forms_completed,
        ad.forms_uploaded_to_elation as adv_forms_uploaded_to_elation,
        ad.is_patient_willing_to_complete_acp as adv_is_patient_willing_to_complete_acp,
        ad.is_patient_tag_updated_dnr as adv_is_patient_tag_updated_dnr,
        ad.reason_patient_declined as adv_reason_patient_declined,
        ad.date_of_acp_education as adv_date_of_acp_education,

    -- workflow-specific sparse columns: safety
        sf.incident_description as sf_incident_description,
        sf.is_aps_report_filed as sf_is_aps_report_filed,
        sf.date_of_aps_report as sf_date_of_aps_report,
        sf.aps_report_outcome as sf_aps_report_outcome,
        sf.case_number as sf_case_number,
        sf.is_provider_team_updated as sf_is_provider_team_updated,
        sf.reason_not_filing_report as sf_reason_not_filing_report,
        sf.who_was_consulted as sf_who_was_consulted,
        coalesce(
            sf.delay_reason,
            ad.delay_reason,
            hv.delay_reason,
            qg.delay_reason,
            po.delay_reason,
            s.delay_reason,
            sd.delay_reason,
            ot.delay_reason
                ) as delay_reason,
        coalesce(
            s.notes,
            sf.notes,
            ad.notes,
            qg.notes,
            hv.notes,
            po.notes,
            sd.notes,
            ot.notes
                ) as notes,
        coalesce(
            s.attachments,
            sf.attachments,
            ad.attachments,
            qg.attachments,
            hv.attachments,
            po.attachments,
            sd.attachments,
            ot.attachments
                ) as attachments,

    -- workflow-specific sparse columns: quality gaps
        qg.specialist_contact_information as qg_specialist_contact_information,
        qg.gap_assistance_types as qg_gap_assistance_types,
        qg.outreach_1 as qg_outreach_1,
        qg.outreach_2 as qg_outreach_2,
        qg.outreach_3 as qg_outreach_3,
        qg.outreach_1_date as qg_outreach_1_date,
        qg.outreach_2_date as qg_outreach_2_date,
        qg.outreach_3_date as qg_outreach_3_date,
        qg.contact_status as qg_contact_status,
        qg.outcome as qg_outcome,
        qg.final_disposition as qg_final_disposition,
        qg.reason_for_decline as qg_reason_for_decline,
        qg.reason_unable_to_schedule as qg_reason_unable_to_schedule,
        qg.appointment_date as qg_appointment_date,
        qg.kit_return_date as qg_kit_return_date,
        (qg.final_disposition in ('Patient Already Completed', 'Appointment Scheduled') or qg.kit_return_date is not null) as is_qg_engagement_successful,
        qg.task_master_created_by_id as qg_task_master_created_by_id,
        qg.task_master_created_by_email as qg_task_master_created_by_email,
        qg.task_master_created_by_name as qg_task_master_created_by_name,
        qg.created_at as qg_created_at,
        qg.created_by_id as qg_created_by_id,
        qg.created_by_email as qg_created_by_email,
        qg.created_by_name as qg_created_by_name,
        qg.outreach_2_outcome_last_modified as qg_outreach_2_outcome_last_modified,

    -- workflow-specific sparse columns: patient outreach
        po.outreach_1 as po_outreach_1,
        po.outreach_1_date as po_outreach_1_date,
        po.outreach_2 as po_outreach_2,
        po.outreach_2_date as po_outreach_2_date,
        po.patient_request_type as po_patient_request_type,
        po.request_routing as po_request_routing,
        po.request_type as po_request_type,

    -- workflow-specific sparse columns: other
        ot.task as ot_task,
        ot.task_description as ot_task_description,

    -- social workflow record creator info
        s.created_datetime as soc_created_datetime,
        s.creator_id as soc_creator_id,
        s.creator_email as soc_creator_email,
        s.creator_name as soc_creator_name,

    -- PAP/LIS specific (from social)
        s.manufacturer_name as soc_manufacturer_name,
        s.rx_name_and_dosage as soc_rx_name_and_dosage,
        s.rx_name_and_dosage_pap as soc_rx_name_and_dosage_pap,
        s.pap_application_submitted as soc_pap_application_submitted,
        s.pap_application_submitted_date as soc_pap_application_submitted_date,
        s.pap_application_type as soc_pap_application_type,
        s.pap_refill_due_date as soc_pap_refill_due_date,
        s.pap_annual_renewal_date as soc_pap_annual_renewal_date,
        s.pap_due_status as soc_pap_due_status,
        s.pap_outcome as soc_pap_outcome,
        s.pap_requires_refill_submissions as soc_pap_requires_refill_submissions,
        s.is_pap_application_uploaded as soc_is_pap_application_uploaded,
        s.is_pap_tag_added as soc_is_pap_tag_added,
        s.is_pharmacy_group_notified as soc_is_pharmacy_group_notified,
        s.lis_application_submitted as soc_lis_application_submitted,
        s.lis_application_submitted_date as soc_lis_application_submitted_date,
        s.lis_application_type as soc_lis_application_type,
        
        s.lis_outcome as soc_lis_outcome,
        s.is_lis_application_uploaded as soc_is_lis_application_uploaded,
        s.lis_renewal_date as soc_lis_renewal_date,
        s.is_lis_tag_added as soc_is_lis_tag_added,
        s.is_lis_screening_completed as soc_is_lis_screening_completed,
        s.lis_screening_date as soc_lis_screening_date,
        s.appears_income_eligible_lis as soc_appears_income_eligible_lis,
        s.appears_income_eligible_pap as soc_appears_income_eligible_pap,
        s.tm_rx_request_rx_name_dosage as soc_tm_rx_request_rx_name_dosage,
        s.tm_rx_request_manufacturer_name as soc_tm_rx_request_manufacturer_name,
        s.tm_rx_request_priority as soc_tm_rx_request_priority,
        s.is_referred_to_broker as soc_is_referred_to_broker,
        s.is_cancelation_notification_sent as soc_is_cancelation_notification_sent,

    -- household / eligibility (from social)
        s.household_size as soc_household_size,
        s.monthly_household_income as soc_monthly_household_income,
        s.household_income_meets_requirement as soc_household_income_meets_requirement,
        s.did_complete_eligibility_screener as soc_did_complete_eligibility_screener,
        s.household_income_proof as soc_household_income_proof,

    -- Medicaid specific (from social)
        s.appears_income_eligible_medicaid as soc_appears_income_eligible_medicaid,
        s.is_medicaid_screening_completed as soc_is_medicaid_screening_completed,
        s.is_medicaid_application_submitted as soc_is_medicaid_application_submitted,
        s.medicaid_application_submitted_date as soc_medicaid_application_submitted_date,
        s.medicaid_renewal_date as soc_medicaid_renewal_date,
        s.medicaid_application_outcome as soc_medicaid_application_outcome,
        s.is_medicaid_application_uploaded as soc_is_medicaid_application_uploaded,
        s.is_patient_willing_to_complete_medicaid as soc_is_patient_willing_to_complete_medicaid,
        s.is_medicaid_submitted_by_cbo as soc_is_medicaid_submitted_by_cbo,
        s.medicaid_application_completion_method as soc_medicaid_application_completion_method,
        s.medicaid_application_assisted_by as soc_medicaid_application_assisted_by,
        coalesce(
            s.compas_note,
            sf.compas_note,
            ad.compas_note,
            qg.compas_note,
            hv.compas_note,
            po.compas_note,
            sd.compas_note,
            ot.compas_note
                ) as compas_note,

    -- SDoH specific (from sdoh)
        sd.tm_sdoh_intervention_request_category as sd_tm_sdoh_intervention_request_category,
        sd.intervention_description as sd_intervention_description,
        sd.intervention_sdoh_category as sd_intervention_sdoh_category,
        sd.falls_alert as sd_falls_alert,
        sd.financial_alert as sd_financial_alert,
        sd.food_alert as sd_food_alert,
        sd.housing_alert as sd_housing_alert,
        sd.transportation_alert as sd_transportation_alert,
        sd.is_elation_zcode_updated as sd_is_elation_zcode_updated,

    -- resolution (coalesced across workflow tables that track explicit resolution)
        coalesce(s.is_resolved, ad.is_resolved, qg.is_resolved, sf.is_resolved, hv.is_resolved, po.is_resolved, sd.is_resolved, ot.is_resolved) as is_resolved,
        coalesce(s.resolved_date::timestamp_tz, sf.resolved_date::timestamp_tz, ad.resolved_at, qg.resolved_at, hv.resolved_at, po.resolved_at, sd.resolved_at, ot.resolved_at) as resolved_at,
        coalesce(s.resolved_by_name, ad.resolved_by_name, qg.resolved_by_name, sf.resolved_by_name, hv.resolved_by_name, po.resolved_by_name, sd.resolved_by_name, ot.resolved_by_name) as resolved_by_name,
        coalesce(s.resolved_by_id, ad.resolved_by_id, qg.resolved_by_id, sf.resolved_by_id, hv.resolved_by_id, po.resolved_by_id, sd.resolved_by_id, ot.resolved_by_id) as resolved_by_id,
        coalesce(s.resolved_by_email, ad.resolved_by_email, qg.resolved_by_email, sf.resolved_by_email, hv.resolved_by_email, po.resolved_by_email, sd.resolved_by_email, ot.resolved_by_email) as resolved_by_email,

    -- derived: completion date (workflow-specific where available, stage_last_modified_at as fallback)
        coalesce(
            hv.hv_completed_date::timestamp_tz,
            s.resolved_date::timestamp_tz,
            ad.resolved_at,
            qg.resolved_at,
            ot.resolved_at,
            case
                when coalesce(
                    s.social_status,
                    sf.safety_status,
                    qg.gap_status,
                    po.outreach_status,
                    sd.sdoh_status,
                    ot.other_status
                            ) = 'Closed'
                then coalesce(
                    s.stage_last_modified_at,
                    sf.stage_last_modified_at,
                    qg.stage_last_modified_at,
                    po.stage_last_modified_at,
                    sd.stage_last_modified_at,
                    ot.stage_last_modified_at)
                        end
                            ) as completed_at,

    -- status flags
        coalesce(
            s.social_status,
            sf.safety_status,
            ad.adv_directive_status,
            qg.gap_status,
            hv.home_visit_status,
            po.outreach_status,
            sd.sdoh_status,
            ot.other_status
                ) = 'Closed'
                    as is_closed,

        coalesce(
            s.social_status,
            sf.safety_status,
            ad.adv_directive_status,
            qg.gap_status,
            hv.home_visit_status,
            po.outreach_status,
            sd.sdoh_status,
            ot.other_status
                ) = 'Open'
                    as is_open,

        coalesce(initcap(trim(coalesce(
            s.social_stage,
            sf.safety_stage,
            ad.adv_directive_stage,
            qg.gap_stage,
            hv.home_visit_stage,
            po.outreach_stage,
            sd.sdoh_stage,
            ot.other_stage
                ))) = 'Patient Declined Participation', false)
                    as is_declined,

        coalesce((coalesce(
            s.social_status,
            sf.safety_status,
            ad.adv_directive_status,
            qg.gap_status,
            hv.home_visit_status,
            po.outreach_status,
            sd.sdoh_status,
            ot.other_status
                ) = 'Closed'
        and initcap(trim(coalesce(
            s.social_stage,
            sf.safety_stage,
            ad.adv_directive_stage,
            qg.gap_stage,
            hv.home_visit_stage,
            po.outreach_stage,
            sd.sdoh_stage,
            ot.other_stage
                ))) = 'Not Started'), false)
                    as is_closed_no_work,

        coalesce((coalesce(
            s.social_status,
            sf.safety_status,
            ad.adv_directive_status,
            qg.gap_status,
            hv.home_visit_status,
            po.outreach_status,
            sd.sdoh_status,
            ot.other_status
                ) = 'Closed'
        and initcap(trim(coalesce(
            s.social_stage,
            sf.safety_stage,
            ad.adv_directive_stage,
            qg.gap_stage,
            hv.home_visit_stage,
            po.outreach_stage,
            sd.sdoh_stage,
            ot.other_stage
                ))) = 'Complete'), false)
                    as is_successfully_resolved,

    -- workflow type flags
        tm.workflow_type = 'Home Visit - TOC' as is_toc_home_visit,
        tm.workflow_type = 'Quality Gaps' as is_quality_gap,
        tm.workflow_type = 'Advance Directives' as is_acp,
        tm.workflow_type = 'Rx Assistance (PAP/LIS)' as is_pap_lis,
        tm.workflow_type = 'Medicaid' as is_medicaid,
        tm.workflow_type = 'SDoH Intervention' as is_sdoh,
        tm.workflow_type = 'APS Report' as is_safety,
        tm.workflow_type in ('Return Phone Call', 'New Patient Outreach') as is_patient_outreach,
        tm.workflow_type = 'Other (Manual)' as is_other,

        -- timeliness metrics
        datediff(day, tm.request_datetime, current_timestamp()) as days_since_request,
        datediff(day, current_timestamp(), tm.due_date) as days_until_due,
        tm.due_date < current_date()
            and coalesce(
                s.social_status,
                sf.safety_status,
                ad.adv_directive_status,
                qg.gap_status,
                hv.home_visit_status,
                po.outreach_status,
                sd.sdoh_status,
                ot.other_status
                    ) = 'Open'
                        as is_overdue,

        datediff(day, tm.request_datetime, completed_at) as days_to_complete,

        -- toc home visit timeliness (within 7 days of request)
        hv.hv_completed_date is not null and datediff(day, tm.request_datetime::date, hv.hv_completed_date) <= 7 as is_toc_hv_on_time,

    -- patient lookups from task master
        tm.high_risk_patient,
        tm.elation_id,
        tm.next_pcp_appt_date,
        tm.next_careteam_appt_date,

    -- task master resolved by (formula and active owner rollup)
        tm.resolved_by_formula as tm_resolved_by_formula,
        tm.resolved_by as tm_resolved_by,

    -- task master active owner (current task owner from Airtable)
        tm.active_owner

    from task_master tm
    left join social s
        on tm.airtable_id = s.task_master_link_id
        and s.snapshot_rank = 1
    left join safety sf
        on tm.airtable_id = sf.task_master_link_id
        and sf.snapshot_rank = 1
    left join adv_directives ad
        on tm.airtable_id = ad.task_master_link_id
        and ad.snapshot_rank = 1
    left join quality_gaps qg
        on tm.airtable_id = qg.task_master_link_id
        and qg.snapshot_rank = 1
    left join home_visit hv
        on tm.airtable_id = hv.task_master_link_id
        and hv.snapshot_rank = 1
    left join patient_outreach po
        on tm.airtable_id = po.task_master_link_id
        and po.snapshot_rank = 1
    left join sdoh sd
        on tm.airtable_id = sd.task_master_link_id
        and sd.snapshot_rank = 1
    left join other ot
        on tm.airtable_id = ot.task_master_link_id
        and ot.snapshot_rank = 1
)

select * from final
    )
;


  