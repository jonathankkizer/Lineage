
  create or replace   view dw_dev.dev_jkizer_staging.stg_leadingreach_contact_tag
  
  copy grants
  
  
  as (
    select 
    contact_id, 
    id as tag_id, 
    type as tag_type, 
    color, 
    name, 
    is_public, 
    display_order, 
    organization,
    created_at, 
    update_at as updated_at
from source_prod.leadingreach.contact_tag
  );

