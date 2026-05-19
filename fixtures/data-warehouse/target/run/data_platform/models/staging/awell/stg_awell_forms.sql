
  create or replace   view dw_dev.dev_jkizer_staging.stg_awell_forms
  
  copy grants
  
  
  as (
    select 
    id as form_id,
    definition_id,
    release_id,
    key,
    title,
    metadata,
    date(last_synced_at) as last_synced_at
from source_prod.awell.forms
  );

