select 
    provider_id, 
    id as email_id, 
    type as email_type,
    address, 
    created_at, 
    updated_at
from source_prod.leadingreach.provider_email