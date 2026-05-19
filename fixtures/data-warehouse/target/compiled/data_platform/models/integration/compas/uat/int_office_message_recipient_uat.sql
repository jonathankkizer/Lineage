select
    seomr.office_messages_recipients_id as member_id,
    coalesce(seomr.sent_to, seomr.staff_group_id) as recipient_id,
    iff(eu.user_id is null, 'Group', 'Staff') as recipient_type,
    coalesce(eu.user_name, seomr.staff_group_name) as recipient_name,
    seomr.status,
    seomr.ack_datetime as acknowledged_datetime
from dw_dev.dev_jkizer_staging.stg_elation_office_messages_recipients seomr
left join dw_dev.dev_jkizer.int_office_message_uat iom
    on seomr.thread_id = iom.thread_id
left join dw_dev.dev_jkizer.ehr_user eu
    on seomr.sent_to = eu.user_id
where
    iom.thread_id is not null