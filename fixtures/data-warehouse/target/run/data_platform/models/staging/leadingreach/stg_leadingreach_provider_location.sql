
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_provider_location
  
  copy grants
  
  
  as (
    select 
    provider_id, 
    id as location_id
from source_prod.leadingreach.provider_location
  );

