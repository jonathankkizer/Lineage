select 
    id as step_id,
    name as step_name,
    definition_id,
    care_flow_definition_id,
    care_flow_id,
    track_id,
    date(started_at) as step_started_at,
    date(completed_at) as step_completed_at,
    date(scheduled_at) as step_scheduled_at,
    duration_in_seconds,
    status,
    date(last_synced_at) as last_synced_at
from source_prod.awell.steps