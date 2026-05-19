select
    ips.suvida_id,
    ips.elation_id,
    ips.first_name,
    ips.last_name,
    ips.gender,
    ips.birth_date,
    fvn.visit_note_id,
    fvn.visit_note_name as visit_note_type,
    svn.physician_user_id,
    phy.physician_id,
    phy.user_email as physician_email,
    fvn.encounter_skey,
    fvn.appointment_encounter_skey,
    appt.appointment_id,
    appt.appointment_datetime_utc,
    svn.document_datetime,
    svn.creation_datetime,
    svn.created_by_user_id,
    cre.user_name as created_by_user_name,
    svn.signed_datetime,
    svn.signed_by_user_id,
    sig.user_email as signed_by_user_email,
    sig.user_name as signed_by_user_name
from dw_dev.dev_jkizer.fct_visit_note fvn
inner join dw_dev.dev_jkizer.int_patient_summary ips
    on fvn.suvida_id = ips.suvida_id
left join dw_dev.dev_jkizer_staging.stg_elation_visit_note svn
    on fvn.visit_note_id = svn.visit_note_id
left join dw_dev.dev_jkizer_staging.stg_elation_vn2_note svn2
    on svn.visit_note_id = svn2.visit_note_id
left join dw_dev.dev_jkizer.ehr_user phy
    on svn.physician_user_id = phy.user_id
left join dw_dev.dev_jkizer.ehr_user sig
    on svn.signed_by_user_id = sig.user_id
left join dw_dev.dev_jkizer.ehr_user cre
    on svn.created_by_user_id = cre.user_id
left join dw_dev.dev_jkizer.fct_appointment appt
    on phy.physician_id = appt.physician_id and
       to_date(svn.document_datetime) = to_date(appt.appointment_datetime_utc) and
       svn.patient_id = appt.elation_id and
       appt.appointment_status not in (
         'cancelled',
         'notSeen'
       )
where
    svn.deletion_datetime is null and
    _is_test_patient = FALSE and
    svn2.visit_note_id is null