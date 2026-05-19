
  create or replace   view dw_dev.dev_jkizer_staging.stg_flowroute_numbers
  
  copy grants
  
  
  as (
    select 
    alias as contact_name, 
    value as phone_number, 
    alias2, 
    value2, 
    route_type, 
    type 
from source_prod.flowroute.numbers
  );

