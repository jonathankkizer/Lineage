
  
    

create or replace transient table dw_dev.dev_jkizer.elation_messaging
    copy grants
    
    
    as (with base as (
    select msg.uq_office_messages as unique_message_key,
    'office_messages' as message_type,
    msg.office_messages_id as message_id,
    suv.suvida_id,
    msg.elation_id,
    msg.thread_id,
    msg.text,
    msg.datetime_sent,
    msg.urgent,
    msg.sender_id,
    msg.post_datetime,
    msg.creation_datetime,
    msg.created_by_user_id,
    msg.deletion_datetime,
    msg.deleted_by_user_id,
    msg.signed_datetime,
    msg.signed_by_user_id,
    msg._idx,
    usr.user_email as sender_email,
    usr.user_name as sender_user_name,
    array_agg(distinct rec.REMOVED_FROM_THREAD) as recipient_removed_from_thread_array,
    array_agg(distinct rec.Removed_at) as recipient_removed_at_array,
    array_agg(distinct rec.sent_to) as recipients_id_array,
    array_agg(distinct usr_rec.user_email) as recipients_email_array,
    array_agg(distinct usr_rec.user_name) as recipients_user_name_array,
    array_agg(distinct rec.staff_group_name) as recipients_staff_group_name_array,
    from dw_dev.dev_jkizer_staging.stg_elation_office_messages msg
    inner join dw_dev.dev_jkizer.suvida_id_walk suv on msg.elation_id = suv.member_id and suv.source = 'Elation'
    left join dw_dev.dev_jkizer_staging.stg_elation_user usr on usr.user_id = msg.sender_id
    left join dw_dev.dev_jkizer_staging.stg_elation_office_messages_recipients rec
    on msg.thread_id = rec.thread_id
    and (rec.sent_to is null or msg.sender_id != rec.sent_to)
    left join dw_dev.dev_jkizer_staging.stg_elation_user usr_rec on usr_rec.user_id = rec.sent_to
    where msg.deletion_datetime is null
    group by all

), office_messages as (
    select *,
        row_number() over (partition by thread_id order by datetime_sent asc) as message_order
    from base

), thread_subject as ( -- add logic to classify threads based on content in their first message
    select
        thread_id,
        case
            when om.text ilike '%#refill%' then 'refill_request'
            when om.text ilike '%trc2025%' then 'TRC2025'
            when om.text ilike '%er2025%' then 'ER2025'
        end as message_subject,
    from office_messages om
    where om.message_order = 1
)
select 
    om.*,
    DATEDIFF(hour, LAG(om.datetime_sent) OVER (
        PARTITION BY om.thread_id 
        ORDER BY om.datetime_sent
    ), om.datetime_sent) AS hours_between_messages_sent,
    DATEDIFF(day, LAG(om.datetime_sent) OVER (
        PARTITION BY om.thread_id 
        ORDER BY om.datetime_sent
    ), om.datetime_sent) AS days_between_messages_sent,
    DATEDIFF(hour, om.datetime_sent, om.signed_datetime) AS hours_between_message_and_signed,
    DATEDIFF(day, om.datetime_sent, om.signed_datetime) AS days_between_message_and_signed,
    ts.message_subject,
from office_messages om
left join thread_subject ts
    on om.thread_id = ts.thread_id
    )
;


  