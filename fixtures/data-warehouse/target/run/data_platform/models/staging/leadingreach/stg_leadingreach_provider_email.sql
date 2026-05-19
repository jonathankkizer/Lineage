
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_provider_email
  
  copy grants
  
  
  as (
    select 
    provider_id, 
    id as email_id, 
    type as email_type,
    address, 
    created_at, 
    updated_at
from source_prod.leadingreach.provider_email
  );

