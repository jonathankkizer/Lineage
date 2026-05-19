
  create or replace   view dw_dev.dev_jkizer_staging.stg_awell_activities
  
  copy grants
  
  
  as (
    select    
    id as activity_id,
    care_flow_id,
    care_flow_definition_id,
    status,
    resolution,
    date(date) as activity_date,
    cast(date as timestamp) as activity_timestamp,
    date(scheduled_date) as scheduled_date,
    date(completion_date) as completion_date,
    action,
    orchestrated_instance_id,
    orchestrated_track_id,
    orchestrated_step_id,
    action_definition_id,
    action_component_name,
    object_type,
    object_name,
    object_id,
    indirect_object_type,
    indirect_object_name,
    step_name,
    track_name,
    track_id,
    date(last_synced_at) as last_synced_at,
    metadata, 
        -- Parse the JSON and extract the timestamp
    to_timestamp(parse_json(metadata):task:requestedPeriod:start::string) as start_date,
    -- Extract the unit and value directly
    parse_json(metadata):task:extension[0]:valueDuration:unit::string as unit,
    parse_json(metadata):task:extension[0]:valueDuration:value::string as value,
    -- Convert to consistent unit: days
    case 
        when lower(parse_json(metadata):task:extension[0]:valueDuration:unit::string) = 'day' then 
            try_cast(parse_json(metadata):task:extension[0]:valueDuration:value::string as int)
        when lower(parse_json(metadata):task:extension[0]:valueDuration:unit::string) = 'week' then 
            try_cast(parse_json(metadata):task:extension[0]:valueDuration:value::string as int) * 7
        else 0 
    end as duration_in_days
from source_prod.awell.activities
  );

