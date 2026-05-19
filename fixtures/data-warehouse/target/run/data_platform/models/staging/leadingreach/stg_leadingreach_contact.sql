
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_contact
  
  copy grants
  
  
  as (
    select 
    id as contact_id, 
    npi, 
    is_no_npi_number, 
    practice_name, 
    first_name, 
    last_name, 
    organization, 
    created_at, 
    updated_at 
from source_prod.leadingreach.contact
  );

