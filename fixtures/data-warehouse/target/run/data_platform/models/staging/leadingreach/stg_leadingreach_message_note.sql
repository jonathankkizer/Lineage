
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_message_note
  
  copy grants
  
  
  as (
    select 
    message_id, 
    note
from source_prod.leadingreach.message_note
  );

