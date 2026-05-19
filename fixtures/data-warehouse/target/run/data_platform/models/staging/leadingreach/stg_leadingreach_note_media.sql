
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_note_media
  
  copy grants
  
  
  as (
    select 
    note_id, 
    media as media_id
from source_prod.leadingreach.note_media
  );

