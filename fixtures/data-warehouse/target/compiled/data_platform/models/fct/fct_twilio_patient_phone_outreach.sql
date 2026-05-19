select
    md5(cast(coalesce(cast(outbound.resource_sid as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(outbound.date_created as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as twilio_phone_outreach_skey,
    outbound.resource_sid,
    outbound.suvida_id,  
    outbound.resource_type,
    outbound.appointment_id,
    outbound.resource_campaign,
    outbound.message as phone_prompt,
    inbound.message as response_input,
    inbound.message_properties as response_properties,
    outbound.destination as patient_phone_number,
    outbound.source as suvida_phone_number,
    outbound.date_created as called_at, 
    inbound.date_created as answered_at
from dw_dev.dev_jkizer_staging.stg_twilio_messaging_resource outbound
left join dw_dev.dev_jkizer_staging.stg_twilio_messaging_resource inbound
    on inbound.resource_sid = outbound.resource_sid 
    and inbound.direction = 'Inbound'
where outbound.direction = 'Outbound' and outbound.resource_type = 'Call'
-- we only want appointment reminders
and outbound.resource_campaign != 'Emergency Communication'