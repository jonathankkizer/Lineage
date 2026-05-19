
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_connected_location_address
  
  copy grants
  
  
  as (
    select 
    location_id, 
    id as address_id,
    type as adress_type,  
    name, 
    website, 
    street1, 
    street2, 
    street3, 
    municipality, 
    administrative_area, 
    postal_code, 
    country_code, 
    created_at, 
    updated_at
from source_prod.leadingreach.connected_location_address
  );

