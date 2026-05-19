with abnormal_lab_results as (
    select distinct lab_report_id
    from dw_dev.dev_jkizer_staging.stg_elation_lab_result selr
    where is_abnormal = TRUE
)

select
    siw.suvida_id,
    patient_id as elation_id,
    ipsu.first_name,
    ipsu.last_name,
    ipsu.gender,
    ipsu.birth_date,
    ipsu.provider_name,
    ipsu.provider_id,
    eu2.user_id as provider_user_id,
    ipsu.provider_email,
    report_id,
    reported_datetime,
    report_type,
    iff(alr.lab_report_id is null, FALSE, TRUE) as is_abnormal_lab,
    requisition_number,
    order_status,
    ordering_provider_name,
    copies_to,
    vendor_name,
    report_title,
    document_date,
    chart_feed_date,
    creation_datetime,
    deletion_datetime,
    signed_datetime,
    signed_by_user_id,
    coalesce(eu.user_staff_id, seu.office_staff_id) as signer_staff_id,
    coalesce(eu.physician_id, seu.physician_id) as signer_physician_id,
    coalesce(eu.user_email, seu.user_email) as signer_email,
    coalesce(eu.user_name, seu.user_name) as signer_name,
    coalesce(eu.user_first_name, seu.user_first_name) as signer_first_name,
    coalesce(eu.user_last_name, seu.user_last_name) as signer_last_name
from dw_dev.dev_jkizer_staging.stg_elation_report ser 
inner join dw_dev.dev_jkizer.suvida_id_walk siw 
    on ser.source = siw.source and
    to_varchar(ser.patient_id) = siw.member_id
left join dw_dev.dev_jkizer.int_patient_summary_uat ipsu
    on siw.suvida_id = ipsu.suvida_id
left join dw_dev.dev_jkizer.ehr_user eu
    on ser.signed_by_user_id = eu.user_id
left join dw_dev.dev_jkizer_staging.stg_elation_user seu
    on ser.signed_by_user_id = seu.user_id
left join abnormal_lab_results alr
    on ser.report_id = alr.lab_report_id
left join dw_dev.dev_jkizer.ehr_user eu2
    on ipsu.provider_id = eu2.physician_id
where
    ipsu.suvida_id is not null and
    signed_datetime is null