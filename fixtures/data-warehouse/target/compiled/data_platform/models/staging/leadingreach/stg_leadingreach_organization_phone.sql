select 
    organization_id, 
    id as organization_phone_id, 
    type, 
    number, 
    extension,
    created_at, 
    updated_at
from source_prod.leadingreach.organization_phone