
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_organization_phone
  
  copy grants
  
  
  as (
    select 
    organization_id, 
    id as organization_phone_id, 
    type, 
    number, 
    extension,
    created_at, 
    updated_at
from source_prod.leadingreach.organization_phone
  );

