
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_connected_provider_phone
  
  copy grants
  
  
  as (
    select 
    provider_id, 
    id as phone_id, 
    type as phone_type, 
    number, 
    extension,
    created_at,
    updated_at,
    specialties
from source_prod.leadingreach.connected_provider_phone
  );

