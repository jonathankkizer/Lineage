
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_message_custom_status
  
  copy grants
  
  
  as (
    select 
    message_id, 
    id as status_id, 
    status, 
    name, 
    is_public, 
    display_order,
    organization, 
    created_at, 
    updated_at
from source_prod.leadingreach.message_custom_status
  );

