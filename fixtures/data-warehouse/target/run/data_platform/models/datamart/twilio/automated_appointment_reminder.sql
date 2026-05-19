
  
    

create or replace transient table dw_dev.dev_jkizer.automated_appointment_reminder
    copy grants
    
    
    as (select
    lgs.suvida_id,
    to_varchar(lgs.appointment_id) as appointment_id,
    event_name,
    grps.language,
    grps.department,
    message,
    'SMS' as message_type,
    lgs.phone as message_destination,
    null as message_source,
    'Outgoing' as message_direction,
    null as is_confirmative,
    lgs.date_created
from source_prod.sms.patient_appointment_reminders_event_logs lgs
left join source_prod.sms.patient_appointment_reminders_events evnts
    on lgs.event_id = evnts.event_id
left join source_prod.sms.patient_appointment_reminders_groups grps
    on lgs.group_id = grps.group_id

union all

select distinct
    inc.suvida_id,
    to_varchar(inc.appointment_id) as appointment_id,
    'Recipient Reply' as event_name,
    grps.language,
    grps.department,
    response as message,
    'SMS' as message_type,
    null as message_destination,
    to_varchar(lgs.phone) as message_source,
    'Incoming' as message_direction,
    upper(to_varchar(inc.is_confirmative)),
    inc.date_created
from source_prod.sms.patient_appointment_reminders_incoming_responses inc
left join source_prod.sms.patient_appointment_reminders_event_logs lgs
    on inc.appointment_id = lgs.appointment_id and
        inc.suvida_id = lgs.suvida_id
left join source_prod.sms.patient_appointment_reminders_groups grps
    on lgs.group_id = grps.group_id

union all 

select distinct
    pt.suvida_id,
    to_varchar(sfu.appointment_id) as appointment_id,
    'Recipient Reply' as event_name,
    grps.language,
    grps.department,
    sfu.response as message,
    'SMS' as message_type,
    null as message_destination,
    to_varchar(sfu.phone) as message_source,
    'Incoming' as message_direction,
    'UNKNOWN' as is_confirmative,
    sfu.date_created
from source_prod.sharepoint.src_sharepoint_automated_appointment_reminder_followups sfu
left join dw_dev.dev_jkizer.dim_patient pt
    on sfu.elation_id = pt.elation_id
left join source_prod.sms.patient_appointment_reminders_event_logs lgs
    on sfu.appointment_id = lgs.appointment_id and
        pt.suvida_id = lgs.suvida_id
left join source_prod.sms.patient_appointment_reminders_groups grps
    on lgs.group_id = grps.group_id
where
    sfu.response not like 'Patient%'
    )
;


  