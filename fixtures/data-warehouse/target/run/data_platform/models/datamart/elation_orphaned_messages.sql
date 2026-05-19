
  
    

create or replace transient table dw_dev.dev_jkizer.elation_orphaned_messages
    copy grants
    
    
    as (with thread_members as (
    select om.elation_id as patient_id, omr.*
    from dw_prod.dw_staging.stg_elation_office_messages om
    left join dw_dev.dev_jkizer_staging.stg_elation_office_messages_recipients omr
        on om.thread_id = omr.thread_id and
        omr.removed_from_thread = FALSE
    where
        om.signed_datetime is null and
        om.deletion_datetime is null
),

threads as (
    select thread_id, patient_id
    from thread_members
    where thread_id is not null
    group by thread_id, patient_id
    having count_if(status = 'ReqAct') = 0
),

latest_messages as (
    select
        thr.thread_id,
        om.urgent,
        om.datetime_sent,
        concat(LEFT(om.text, 100), iff(length(om.text) > 100, '...', '')) as message_body,
        sender_id,
    from threads thr
    inner join dw_dev.dev_jkizer_staging.stg_elation_office_messages om
        on thr.thread_id = om.thread_id
    qualify row_number() over (partition by thr.thread_id order by om.datetime_sent desc) = 1
)

select
    thr.thread_id,
    lm.datetime_sent as latest_message_datetime,
    to_date(lm.datetime_sent) as latest_message_date,
    lm.message_body as latest_message_body,
    lm.sender_id as latest_message_sender_id,
    u2.user_name as latest_message_sender,
    lm.urgent as is_urgent,
    ps.suvida_id,
    ps.elation_id,
    coalesce(ps.first_name, pt.first_name, pt2.first_name) as first_name,
    coalesce(ps.last_name, pt.last_name, pt2.last_name) as last_name,
    coalesce(provider_name, u.user_name) as provider_name,
    location_name
from threads thr
left join latest_messages lm
    on thr.thread_id = lm.thread_id
left join dw_dev.dev_jkizer.patient_summary  ps
    on to_varchar(thr.patient_id) = ps.elation_id
left join dw_dev.dev_jkizer_staging.stg_elation_patient pt
    on to_varchar(thr.patient_id) = pt.elation_id
left join elationhealth_ehdw_azure_scentralus_texas_elation_suvida_snowflake_secure_share.suvida.patient pt2
    on thr.patient_id = pt2.id
left join dw_dev.dev_jkizer.ehr_user u
    on pt.primary_physician_user_id = u.user_id
left join dw_dev.dev_jkizer.ehr_user u2
    on lm.sender_id = u2.user_id
where
    _is_test_patient = FALSE and
    pt2.deletion_time is null
order by
    latest_message_date desc
    )
;


  