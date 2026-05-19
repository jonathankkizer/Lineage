
  
    

create or replace transient table dw_dev.dev_jkizer.patient_communication
    copy grants
    
    
    as (-- Aggregates patient communication from various channels including:
-- - Twilio
-- - TalkDesk
-- - Teams
-- - CareNet
-- Communication data is normalized in intmdt_patient_communication and
-- enriched with patient identity here via dim_patient.
-- Patient matching checks both phone and secondary_phone via unpivot for better performance.

with patient_phones as (
    select
        suvida_id,
        phone as phone_clean
    from dw_dev.dev_jkizer.dim_patient
    where phone is not null

    union all

    select
        suvida_id,
        secondary_phone as phone_clean
    from dw_dev.dev_jkizer.dim_patient
    where secondary_phone is not null
)

select
    patient_communication_skey,
    ic.interaction_id,
    max(coalesce(ic.suvida_id, pp.suvida_id)) as suvida_id,
    ic.direction,
    ic.phone,
    ic.from_number,
    ic.talkdesk_phone_display_name,
    ic.patient_phone,
    ic."user",
    ic."timestamp" as call_start_time,
    ic.duration_time_seconds,
    ic.ring_time_seconds,
    ic.wait_time_seconds,
    ic.hold_time_seconds,
    ic.campaign,
    ic.context,
    ic.disposition_code,
    ic.disposition_set,
    ic.nested_disposition,
    ic.delivery_method,
    ic.platform,
    ic.status,
    ic.is_completed
from dw_dev.dev_jkizer.intmdt_patient_communication ic
left join patient_phones pp
    on ic.patient_phone = pp.phone_clean
    and ic.suvida_id is null
group by all
    )
;


  