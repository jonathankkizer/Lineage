
  create or replace   view dw_dev.dev_jkizer_staging.stg_sharepoint_site_users
  
  copy grants
  
  
  as (
    select
    cast(id as integer) as user_id,
    cast(title as varchar) as display_name,
    cast(name as varchar) as login_name,
    coalesce(cast(deleted as boolean), false) as is_deleted
from source_prod.sharepoint_list.site_users
  );

