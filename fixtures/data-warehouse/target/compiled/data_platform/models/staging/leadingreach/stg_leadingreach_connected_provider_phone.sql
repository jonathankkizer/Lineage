select 
    provider_id, 
    id as phone_id, 
    type as phone_type, 
    number, 
    extension,
    created_at,
    updated_at,
    specialties
from source_prod.leadingreach.connected_provider_phone