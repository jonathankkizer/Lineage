
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_connected_provider_email
  
  copy grants
  
  
  as (
    select 
    provider_id, 
    id as provider_email_id, 
    type,
    address,
    created_at,
    updated_at 
from source_prod.leadingreach.connected_provider_email
  );

