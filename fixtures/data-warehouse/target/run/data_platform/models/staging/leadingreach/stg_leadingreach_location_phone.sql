
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_location_phone
  
  copy grants
  
  
  as (
    select 
    location_id, 
    id as location_phone_id, 
    type as phone_type, 
    number as contact_number, 
    extension, 
    created_at, 
    updated_at
from source_prod.leadingreach.location_phone
  );

