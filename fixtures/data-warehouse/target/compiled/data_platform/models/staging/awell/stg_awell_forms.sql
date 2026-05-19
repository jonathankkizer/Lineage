select 
    id as form_id,
    definition_id,
    release_id,
    key,
    title,
    metadata,
    date(last_synced_at) as last_synced_at
from source_prod.awell.forms