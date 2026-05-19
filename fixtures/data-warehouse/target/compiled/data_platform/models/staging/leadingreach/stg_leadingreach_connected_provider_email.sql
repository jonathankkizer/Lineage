select 
    provider_id, 
    id as provider_email_id, 
    type,
    address,
    created_at,
    updated_at 
from source_prod.leadingreach.connected_provider_email