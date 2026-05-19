
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_tag
  
  copy grants
  
  
  as (
    select 
    id as tag_id, 
    type, 
    color,
    name,
    is_public, 
    display_order,
    created_at,
    updated_at,
    organization
from source_prod.leadingreach.tag
  );

