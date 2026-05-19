
  create or replace   view dw_dev.dev_jkizer_staging.stg_talkdesk_users
  
  copy grants
  
  
  as (
    /*
    Purpose: staging model from Talkdesk contact center.
    Primary Key: id
    Grain: one row per user (includes patients)
*/


select
    id,
    name
from fivetran_source_prod.talkdesk.users
  );

