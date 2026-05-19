/*
    Teams call records — Lightdash-facing datamart.

    Sourced from the Microsoft Graph callRecords resource (teams.call_record) via
    intmdt_teams_call_record. Replaces the prior direct-routing-based model
    (src_graph_direct_routing_call_records). SIP / SBC diagnostic columns
    (final_sip_code, call_end_sub_reason, media_bypass_enabled, signaling_location,
    trunk_fully_qualified_domain_name, invite_date_time, failure_date_time,
    correlation_id, is_failed_call) are dropped. New columns: clinic_name,
    is_clinic_call, was_answered_by_suvidano, ended_in_voicemail,
    missed_call_reason, is_unanswered_clinic_call.
*/

select
    cr.id,
    cr.call_type,
    cr.is_inbound_call,
    cr.is_inbound_auto_attend,
    cr.is_outbound_auto_attend,
    cr.is_outbound_call,
    cr.is_conference_call,

    cr.callee_number,
    cr.callee_number_clean,
    cr.caller_number,
    cr.caller_number_clean,

    date(convert_timezone('UTC', 'America/Chicago', cr.start_date_time)) as start_date,
    to_char(cr.start_date_time, 'HH12:MI:SS AM') as start_time_utc,
    to_char(convert_timezone('UTC', 'America/Chicago', cr.start_date_time), 'HH12:MI:SS AM') as start_time_cst,

    date(convert_timezone('UTC', 'America/Chicago', cr.end_date_time)) as end_date,
    to_char(cr.end_date_time, 'HH12:MI:SS AM') as end_time_utc,
    to_char(convert_timezone('UTC', 'America/Chicago', cr.end_date_time), 'HH12:MI:SS AM') as end_time_cst,

    cr.duration_seconds,
    round(cr.duration_seconds / 60.0, 2) as duration_minutes,
    cr.is_more_than_5_min_call,

    cr.successful_call,
    cr.is_missed_call,
    cr.missed_call_reason,
    cr.is_unanswered_clinic_call,
    cr.is_clinic_call,
    cr.was_answered_by_suvidano,
    cr.ended_in_voicemail,
    cr.had_auto_attendant,
    cr.had_call_queue,

    cr.clinic_name,
    cr.clinic_location_id,
    cr.clinic_name_source,

    cr.aa_cq_queue_category,
    cr.aa_cq_queue_display_name,
    cr.caller_queue_display_name,
    cr.caller_queue_category,
    cr.callee_queue_display_name,
    cr.callee_queue_category,

    cr.organizer_user_display_name,
    cr.organizer_user_display_name as user_display_name,

    cr.organizer_user_id as teams_organizer_user_id,
    cr.organizer_user_id as teams_user_id,
    seu.user_id as elation_user_id,

    cr.organizer_user_email,
    cr.organizer_user_email as user_principal_name,

    cr.ring_time_seconds,

    seu.elation_team,
    seu.user_name as elation_user_name,

    drs.full_name             as rippling_full_name,
    drs.title                 as rippling_title,
    drs.department            as rippling_department,
    drs.work_location         as rippling_work_location,
    drs.work_location_city    as rippling_work_location_city,
    drs.work_location_state   as rippling_work_location_state,
    drs.work_location_zip     as rippling_work_location_zip,
    drs.location_description  as rippling_location_description,
    drs.job_family_name       as rippling_job_family_name

from dw_prod.dw.intmdt_teams_call_record cr
left join dw_prod.dw_staging.stg_elation_user seu
    on cr.organizer_user_email = seu.user_email
left join dw_prod.dw.dim_rippling_staff drs
    on cr.organizer_user_email = drs.work_email