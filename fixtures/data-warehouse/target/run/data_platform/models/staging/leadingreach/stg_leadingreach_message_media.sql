
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_message_media
  
  copy grants
  
  
  as (
    select 
    message_id, 
    media as media_id
from source_prod.leadingreach.message_media
  );

