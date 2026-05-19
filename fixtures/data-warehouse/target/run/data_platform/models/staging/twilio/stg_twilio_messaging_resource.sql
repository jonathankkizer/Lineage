
  create or replace   view dw_dev.dev_jkizer_staging.stg_twilio_messaging_resource
  
  copy grants
  
  
  as (
    select
    suvida_id,
    resource_sid,
    resource_type,
    replace(resource_context:appointment_id, '"', '') as appointment_id,
    resource_campaign,
    direction,
    message,
    message_properties,
    status,
    destination,
    source,
    date_created
from source_prod.messaging.resource
  );

