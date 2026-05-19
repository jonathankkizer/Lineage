
  
    

create or replace transient table dw_dev.dev_jkizer.int_queue_uat
    copy grants
    
    
    as (select
    suvida_id,
    elation_id,
    first_name,
    last_name,
    gender,
    birth_date,
    provider_name,
    recipient_id as assignee_user_id,
    recipient_staff_id as assignee_staff_id,
    recipient_physician_id as assignee_physician_id,
    recipient_email as assignee_email,
    message_id as queue_item_id,
    thread_id as queue_item_parent_id,
    substring(text, 0, 50) as queue_item_title,
    'Office Message' as queue_item_type,
    case
        when is_urgent = TRUE then 'Urgent Message'
        else 'Office Message'
    end as queue_item_sub_type,
    is_urgent,
    false as is_abnormal,
    creation_datetime,
    acknowledged_datetime as resolved_datetime,
    deletion_datetime
from dw_dev.dev_jkizer.int_office_message_uat
where _idx = 1

union all

select
    suvida_id,
    elation_id,
    first_name,
    last_name,
    gender,
    birth_date,
    provider_name,
    provider_user_id as assignee_user_id,
    null as assignee_staff_id,
    provider_id as assignee_physician_id,
    provider_email as assignee_email,
    report_id as queue_item_id,
    try_to_number(requisition_number, 38, 0) as queue_item_parent_id,
    report_title as queue_item_title,
    'Report' as queue_item_type,
    report_type || ' Report' as queue_item_sub_type,
    false as is_urgent,
    is_abnormal_lab as is_abnormal,
    creation_datetime,
    signed_datetime as resolved_datetime,
    deletion_datetime
from dw_dev.dev_jkizer.int_report_uat
    )
;


  