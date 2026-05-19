with problems as (
    select
        ps.suvida_id,
        ps.elation_id,
        p.patient_problem_id,
        p.rank,
        pc.icd10
    from dw_dev.dev_jkizer.int_patient_summary_uat ps
    left join dw_dev.dev_jkizer_staging.stg_elation_patient_problem p
        on ps.elation_id = to_varchar(p.patient_id)
    left join dw_dev.dev_jkizer_staging.stg_elation_patient_problem_code pc
        on p.patient_problem_id = pc.patient_problem_id
    where
        ps.elation_id is not null and
        p.deletion_datetime is null and 
        p.resolved_date is null
)

select
    ps.suvida_id,
    ps.elation_id,
    p.patient_problem_id as problem_id,
    p.rank,
    fe.encounter_skey,
    fe.appointment_encounter_skey,
    fa.appointment_id,
    fa.appointment_datetime_utc,
    fa.appointment_type,
    fe.bill_id,
    fe.billing_date,
    vn.visit_note_id,
    vn.visit_note_name as visit_note_type,
    vnb.visit_note_bullet_id,
    vnb.last_modified_datetime as visit_note_bullet_last_modified,
    vnb.category as visit_note_bullet_category,
    vnb.text as visit_note_bullet_text,
    vn.physician_user_id,
    vn.document_date,
    icd.imo_id,
    icd.icd10_id as icd_id,
    icd.code as icd_code,
    icd.code_description as icd_description
from dw_dev.dev_jkizer.int_patient_summary_uat ps
left join dw_dev.dev_jkizer_staging.stg_elation_visit_note vn
    on ps.elation_id = vn.patient_id
left join dw_dev.dev_jkizer_staging.stg_elation_visit_note_bullet vnb
    on vn.visit_note_id = vnb.visit_note_id
left join dw_dev.dev_jkizer_staging.stg_elation_visit_note_bullet_imo_join vnbij
    on vnb.visit_note_bullet_id = vnbij.visit_note_bullet_id
left join dw_dev.dev_jkizer_staging.stg_elation_icd10 icd
    on vnbij.imo_id = icd.imo_id
left join dw_dev.dev_jkizer.fct_diagnosis di
    on vn.visit_note_id = di.visit_note_id and
       replace(icd.code, '.', '') = di.icd_10_code
left join dw_dev.dev_jkizer.fct_encounter fe
    on vn.visit_note_id = fe.visit_note_id and
       ps.suvida_id = fe.suvida_id
left join dw_dev.dev_jkizer.fct_appointment fa
    on ps.suvida_id = fa.suvida_id and
       vn.document_date = fa.appointment_date and
       vn.physician_user_id = fa.user_id
left join problems p
    on ps.suvida_id = p.suvida_id and
       icd.icd10_id = p.icd10
where
    ps.elation_id is not null and
    vn.visit_note_id is not null and
    vn.deletion_datetime is null and
    vnb.deleted_datetime is null and
    vnbij.visit_note_bullet_id is not null and
    p.patient_problem_id is not null and
    vn.visit_note_name = 'Provider Note'
qualify row_number() over (partition by ps.elation_id, icd_code order by visit_note_bullet_last_modified desc) = 1