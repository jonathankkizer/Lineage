
  create or replace   view dw_dev.dev_jkizer_staging.stg_messaging_resource_status
  
  copy grants
  
  
  as (
    select
    resource_sid,
    status,
    status_date
from source_prod.messaging.resource_status
  );

