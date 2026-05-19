
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_organization_email
  
  copy grants
  
  
  as (
    select 
    organization_id, 
    id as organization_email_id, 
    type, 
    address, 
    created_at, 
    updated_at
from source_prod.leadingreach.organization_email
  );

