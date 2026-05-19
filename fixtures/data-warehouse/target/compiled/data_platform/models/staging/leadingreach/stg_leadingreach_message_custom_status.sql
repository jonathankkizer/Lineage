select 
    message_id, 
    id as status_id, 
    status, 
    name, 
    is_public, 
    display_order,
    organization, 
    created_at, 
    updated_at
from source_prod.leadingreach.message_custom_status