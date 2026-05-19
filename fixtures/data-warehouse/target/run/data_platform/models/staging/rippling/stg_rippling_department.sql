
  create or replace   view dw_dev.dev_jkizer_staging.stg_rippling_department
  
  copy grants
  
  
  as (
    select
    id,
    created_at,
    updated_at,
    name,
    reference_code,
    parent_id,
    _fivetran_deleted,
    _fivetran_synced

from fivetran_source_prod.rippling.department
  );

