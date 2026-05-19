
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_connected_organization
  
  copy grants
  
  
  as (
    select 
    id as organization_id, 
    npi, 
    name, 
    website, 
    created_at, 
    updated_at
from source_prod.leadingreach.connected_organization
  );

