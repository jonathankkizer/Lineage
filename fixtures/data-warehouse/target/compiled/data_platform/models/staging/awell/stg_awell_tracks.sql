select 
    id as track_id,
    name as track_name,
    definition_id,
    care_flow_definition_id,
    care_flow_id,
    date(started_at) as track_started_at,
    date(completed_at) as track_completed_at,
    date(scheduled_at) as track_scheduled_at,
    duration_in_seconds,
    status,
    date(last_synced_at) as last_synced_at
from source_prod.awell.tracks