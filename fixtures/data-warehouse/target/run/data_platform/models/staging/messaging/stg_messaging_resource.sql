
  create or replace   view dw_dev.dev_jkizer_staging.stg_messaging_resource
  
  copy grants
  
  
  as (
    select
    resource_sid,
    suvida_id,
    direction,
    
    
    case
        when regexp_replace(destination, '[^0-9]', '') = '' then null
        when length(regexp_replace(destination, '[^0-9]', '')) = 11
            and left(regexp_replace(destination, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(destination, '[^0-9]', ''), 10)
        when length(regexp_replace(destination, '[^0-9]', '')) = 10
            then regexp_replace(destination, '[^0-9]', '')
        else null
    end
 as destination,
    
    
    case
        when regexp_replace(source, '[^0-9]', '') = '' then null
        when length(regexp_replace(source, '[^0-9]', '')) = 11
            and left(regexp_replace(source, '[^0-9]', ''), 1) = '1'
            then right(regexp_replace(source, '[^0-9]', ''), 10)
        when length(regexp_replace(source, '[^0-9]', '')) = 10
            then regexp_replace(source, '[^0-9]', '')
        else null
    end
 as source,
    resource_type,
    resource_campaign,
    resource_context,
    date_created
from source_prod.messaging.resource
  );

