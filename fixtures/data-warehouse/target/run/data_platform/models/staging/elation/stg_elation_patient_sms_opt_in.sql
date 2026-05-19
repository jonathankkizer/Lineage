
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_patient_sms_opt_in
  
  copy grants
  
  
  as (
    select
    *
from source_prod.elation.patient_sms_opt_in
  );

