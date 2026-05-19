/*
    Purpose: staging model from Talkdesk contact center.
    Primary Key: callsid
    Grain: one row per call
*/

select
    id as callsid,
    call_type as type,
    
    
    case
        when regexp_replace(customer_phone_number, '[^0-9]', '') = '' then null
        when length(regexp_replace(customer_phone_number, '[^0-9]', '')) = 11
            and left(regexp_replace(customer_phone_number, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(customer_phone_number, '[^0-9]', ''), 10)
        when length(regexp_replace(customer_phone_number, '[^0-9]', '')) = 10
            then regexp_replace(customer_phone_number, '[^0-9]', '')
        else null
    end
 as contact_phone_number, 
    
    
    case
        when regexp_replace(talkdesk_phone_number, '[^0-9]', '') = '' then null
        when length(regexp_replace(talkdesk_phone_number, '[^0-9]', '')) = 11
            and left(regexp_replace(talkdesk_phone_number, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(talkdesk_phone_number, '[^0-9]', ''), 10)
        when length(regexp_replace(talkdesk_phone_number, '[^0-9]', '')) = 10
            then regexp_replace(talkdesk_phone_number, '[^0-9]', '')
        else null
    end
 as talkdesk_phone_number,
    phone_display_name as talkdesk_phone_display_name,
    disposition_code,
    agent_speed_to_answer as total_ringing_time,
    waiting_time as wait_time,
    holding_time as hold_time,
    start_time as start_at,
    end_time as end_at
from fivetran_source_prod.talkdesk.call