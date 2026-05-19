
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_patient_tag
  
  copy grants
  
  
  as (
    select 
    patient_id, 
    id as patient_tag_id, 
    type, 
    color,
    name,
    is_public, 
    display_order,
    organization,
    created_at,
    updated_at
from source_prod.leadingreach.patient_tag
  );

