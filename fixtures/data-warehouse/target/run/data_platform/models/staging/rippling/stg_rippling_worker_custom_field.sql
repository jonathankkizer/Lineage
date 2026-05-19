
  create or replace   view dw_dev.dev_jkizer_staging.stg_rippling_worker_custom_field
  
  copy grants
  
  
  as (
    select
    worker_id,
    index,
    name,
    type,
    value,
    _fivetran_deleted,
    _fivetran_synced

from fivetran_source_prod.rippling.worker_custom_field
  );

