
  create or replace   view dw_dev.dev_jkizer_staging.stg_sandbox_ehr_patient
  
  copy grants
  
  
  as (
    select *
from source_prod.sandbox.ehr_patient
  );

