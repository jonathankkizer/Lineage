
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_connected_provider
  
  copy grants
  
  
  as (
    select 
    id as provider_id, 
    npi as provider_npi, 
    is_no_npi_number, 
    first_name, 
    last_name, 
    name_prefix, 
    name_suffix, 
    created_at, 
    updated_at,
    organization, 
    default_location
from source_prod.leadingreach.connected_provider
  );

