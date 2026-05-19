
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_message_tag
  
  copy grants
  
  
  as (
    select 
    message_id, 
    tag as tag_id
from source_prod.leadingreach.message_tag
  );

