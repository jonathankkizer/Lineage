
  
    

create or replace transient table dw_dev.dev_jkizer.int_patient_communication
    copy grants
    
    
    as (select
    pc.interaction_id,
    pc.suvida_id,
    ips.elation_id,
    pc.direction,
    pc.phone,
    pc.from_number,
    pc.user,
    pc.duration_time_seconds,
    pc.ring_time_seconds,
    pc.wait_time_seconds,
    pc.hold_time_seconds,
    pc.campaign,
    pc.context,
    pc.delivery_method,
    pc.platform,
    pc.call_start_time as timestamp
from dw_dev.dev_jkizer.patient_communication pc
left join dw_dev.dev_jkizer.int_patient_summary ips
    on pc.suvida_id = ips.suvida_id
    )
;


  