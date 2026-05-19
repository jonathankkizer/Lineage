
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_patient_phone
  
  copy grants
  
  
  as (
    select 
    patient_id, 
    id as patient_phone_id, 
    type, 
    number, 
    extension,
    created_at,
    updated_at
from source_prod.leadingreach.patient_phone
  );

