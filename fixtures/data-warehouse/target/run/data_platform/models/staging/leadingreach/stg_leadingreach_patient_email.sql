
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_patient_email
  
  copy grants
  
  
  as (
    select 
    patient_id, 
    id as patient_email_id, 
    type, 
    address, 
    created_at,
    updated_at
from source_prod.leadingreach.patient_email
  );

