select 
    id as patient_id, 
    profile_id, 
    status,
    date(last_synced_at) as last_synced_at
from source_prod.awell.patients