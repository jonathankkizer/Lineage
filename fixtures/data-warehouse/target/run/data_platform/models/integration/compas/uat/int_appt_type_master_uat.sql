
  
    

create or replace transient table dw_dev.dev_jkizer.int_appt_type_master_uat
    copy grants
    
    
    as (select
    appointment_type,
    group_1,
    group_2,
    appointment_provider_category,
    appointment_type_category,
    visit_type,
    visit_level,
    visit_method,
    visit_location_type
from dw_dev.dev_jkizer_source.map_appt_type_group
    )
;


  