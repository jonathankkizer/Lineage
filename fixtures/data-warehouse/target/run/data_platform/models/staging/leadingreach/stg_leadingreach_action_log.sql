
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_action_log
  
  copy grants
  
  
  as (
    select 
    date_created, 
    action,
    id as patient_id,
    prev_state, 
    new_state 
from source_prod.leadingreach.action_log
  );

