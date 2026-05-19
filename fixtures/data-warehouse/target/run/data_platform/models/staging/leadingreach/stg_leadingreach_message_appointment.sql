
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_message_appointment
  
  copy grants
  
  
  as (
    select 
    message_id, 
    appointment as appointment_id
from source_prod.leadingreach.message_appointment
  );

