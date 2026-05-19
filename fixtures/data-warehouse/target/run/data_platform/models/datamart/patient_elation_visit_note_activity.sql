
  
    

create or replace transient table dw_dev.dev_jkizer.patient_elation_visit_note_activity
    copy grants
    
    
    as (select 
    encounter.encounter_skey,
    fct.*, 
    try_cast(response as integer) response_numeric,
    encounter.visit_note_name, 
    encounter.provider_name
from dw_dev.dev_jkizer.fct_elation_note_activity fct
left join dw_dev.dev_jkizer.patient_encounter encounter 
    on encounter.visit_note_id = fct.visit_note_id 
where encounter.signed_date is not null
    )
;


  