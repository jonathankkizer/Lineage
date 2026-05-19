
  create or replace   view dw_dev.dev_jkizer_staging.stg_data_ops_insurance_updates
  
  copy grants
  
  
  as (
    select
    suvida_id,
    elation_id,
    date_patched as event_at
from source_prod.insurance.patient_insurance_updates
where date_patched is not null
  );

