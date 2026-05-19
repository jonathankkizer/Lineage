
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_location
  
  copy grants
  
  
  as (
    select 
    id as location_id, 
    type as location_type, 
    is_default, 
    name, 
    description, 
    timezone, 
    organization 
from source_prod.leadingreach.location
  );

