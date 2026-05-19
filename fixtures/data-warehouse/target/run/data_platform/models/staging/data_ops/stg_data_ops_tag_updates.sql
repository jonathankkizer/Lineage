
  create or replace   view dw_dev.dev_jkizer_staging.stg_data_ops_tag_updates
  
  copy grants
  
  
  as (
    select
    suvida_id,
    elation_id,
    date_patched as event_at
from source_prod.tags.patient_tag_updates
where date_patched is not null
  );

