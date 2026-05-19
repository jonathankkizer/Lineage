
  create or replace   view dw_dev.dev_jkizer_staging.stg_sandbox_patient_mapping
  
  copy grants
  
  
  as (
    select *
from source_prod.sandbox.patient_mapping
  );

