
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_contact_specialty
  
  copy grants
  
  
  as (
    select 
    contact_id, 
    id as specialty_id, 
    code, 
    grouping, 
    classification, 
    specialization, 
    display_name, 
from source_prod.leadingreach.contact_specialty
  );

