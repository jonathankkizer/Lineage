
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_contact_email
  
  copy grants
  
  
  as (
    select 
    contact_id, 
    id as email_id, 
    type as email_type, 
    address as email_address, 
    created_at, 
    updated_at 
from source_prod.leadingreach.contact_email
  );

