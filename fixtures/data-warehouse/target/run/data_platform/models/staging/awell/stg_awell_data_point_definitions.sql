
  create or replace   view dw_dev.dev_jkizer_staging.stg_awell_data_point_definitions
  
  copy grants
  
  
  as (
    select 
    id as data_point_definition_id,
    definition_id,
    release_id,
    source_definition_id,
    category,
    key,
    options,
    value_type,
    date(last_synced_at) as last_synced_at
from source_prod.awell.data_point_definitions
  );

