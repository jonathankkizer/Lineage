
  
    

create or replace transient table dw_dev.dev_jkizer.patient_twilio_phone_outreach
    copy grants
    
    
    as (select
*
from dw_dev.dev_jkizer.fct_twilio_patient_phone_outreach
    )
;


  