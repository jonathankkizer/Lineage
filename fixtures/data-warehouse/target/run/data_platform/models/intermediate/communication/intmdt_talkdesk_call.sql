
  
    

create or replace transient table dw_dev.dev_jkizer.intmdt_talkdesk_call
    copy grants
    
    
    as (/*
    Purpose: Intermediate model combining Talkdesk call, contact_call, and user data into a unified call record with timing and agent details.
    Grain: One row per call.
    Usage: Used to represent Talkdesk communication data downstream in intmdt_patient_communication.
*/

select
    call.callsid,
    call.type,
    call.contact_phone_number,
    call.talkdesk_phone_number,
    call.talkdesk_phone_display_name,
    users.name as user_name,
    call.disposition_code,
    datediff(second, call.start_at, call.end_at) as total_time,
    call.total_ringing_time,
    call.wait_time,
    call.hold_time,
    call.start_at
from dw_dev.dev_jkizer_staging.stg_talkdesk_call as call
left join dw_dev.dev_jkizer_staging.stg_talkdesk_contact_call as contact_call
    on contact_call.interaction_id = call.callsid
left join dw_dev.dev_jkizer_staging.stg_talkdesk_users as users
    on users.id = contact_call.user_id
-- a call can have multiple contact_call records; keep one row per call
qualify row_number() over (partition by call.callsid order by call.start_at desc) = 1
    )
;


  