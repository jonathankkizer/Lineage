
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_note
  
  copy grants
  
  
  as (
    select 
    id as note_id, 
    type as note_type, 
    note, 
    event_date, 
    is_internal, 
    is_viewed,
    created_at, 
    updated_at, 
    by_organization, 
    message, 
    media
from source_prod.leadingreach.note
  );

