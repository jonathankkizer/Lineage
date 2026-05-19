
  create or replace   view dw_dev.dev_jkizer_staging.stg_awell_published_careflows
  
  copy grants
  
  
  as (
    select 
    id as published_careflow_id,
    definition_id,
    title,
    release_id,
    cast(version_number as int) version_number,
    date(last_synced_at) as last_synced_at,
    date(publish_time) as publish_time
from source_prod.awell.published_careflows
  );

