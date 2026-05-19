
  
    

create or replace transient table dw_dev.dev_jkizer.int_office_message
    copy grants
    
    
    as (select distinct
    fom.thread_id,
    fom.office_messages_id as message_id,
    fom.suvida_id,
    fom.elation_id,
    ipsu.first_name,
    ipsu.last_name,
    ipsu.gender,
    ipsu.provider_name,
    ipsu.birth_date,
    fom.text,
    fom.urgent as is_urgent,
    fom.sender_id,
    coalesce(eu.user_staff_id, seu.office_staff_id)  as sender_staff_id,
    coalesce(eu.physician_id, seu.physician_id) as sender_physician_id,
    coalesce(eu.user_email, seu.user_email) as sender_email,
    coalesce(eu.user_name, seu.user_name) as sender_name,
    coalesce(eu.user_first_name, seu.user_first_name) as sender_first_name,
    coalesce(eu.user_last_name, seu.user_last_name) as sender_last_name,    
    seomr.office_messages_recipients_id as recipient_member_id,
    coalesce(seomr.sent_to, seomr.staff_group_id) as recipient_id,
    seu.office_staff_id as recipient_staff_id,
    seu.physician_id as recipient_physician_id,
    iff(eu3.user_id is null, 'Group', 'Staff') as recipient_type,
    coalesce(eu3.user_name, seomr.staff_group_name) as recipient_name,
    coalesce(eu3.user_email, seu2.user_email) as recipient_email,
    fom.datetime_sent as sent_datetime,
    fom.post_datetime,
    fom.creation_datetime,
    fom.created_by_user_id,
    fom.deletion_datetime,
    fom.deleted_by_user_id,
    seomr.ack_datetime as acknowledged_datetime,
    fom.signed_by_user_id,
    eu2.user_staff_id as signer_staff_id,
    eu2.physician_id as signer_physician_id,
    eu2.user_email as signer_email,
    eu2.user_name as signer_name,
    eu2.user_first_name as signer_first_name,
    eu2.user_last_name as signer_last_name,
    dense_rank() over (partition by fom.thread_id, seomr.sent_to order by fom.datetime_sent desc) as _idx
from dw_dev.dev_jkizer_staging.stg_elation_office_messages_recipients seomr
left join dw_dev.dev_jkizer.fct_office_message fom
    on seomr.thread_id = fom.thread_id
left join dw_dev.dev_jkizer.int_patient_summary ipsu
    on ipsu.suvida_id = fom.suvida_id
left join dw_dev.dev_jkizer.ehr_user eu
    on fom.sender_id = eu.user_id
left join dw_dev.dev_jkizer.ehr_user eu2
    on fom.signed_by_user_id = eu2.user_id
left join dw_dev.dev_jkizer_staging.stg_elation_user seu
    on fom.sender_id = seu.user_id
left join dw_dev.dev_jkizer.ehr_user eu3
    on seomr.sent_to = eu3.user_id
left join dw_dev.dev_jkizer_staging.stg_elation_user seu2
    on seomr.sent_to = seu2.user_id
where
    ipsu.suvida_id is not null and
    seomr.status = 'ReqAct' and
    seomr.sent_to is not null
    )
;


  