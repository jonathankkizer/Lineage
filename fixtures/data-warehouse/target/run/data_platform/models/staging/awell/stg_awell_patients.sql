
  create or replace   view dw_dev.dev_jkizer_staging.stg_awell_patients
  
  copy grants
  
  
  as (
    select 
    id as patient_id, 
    profile_id, 
    status,
    date(last_synced_at) as last_synced_at
from source_prod.awell.patients
  );

