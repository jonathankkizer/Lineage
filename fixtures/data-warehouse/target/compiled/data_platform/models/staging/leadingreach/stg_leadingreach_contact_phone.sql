select 
    contact_id, 
    id as phone_id, 
    type as phone_type, 
    number, 
    extension, 
    created_at, 
    updated_at 
from source_prod.leadingreach.contact_phone