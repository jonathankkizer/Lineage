select 
    contact_id, 
    id as tag_id, 
    type as tag_type, 
    color, 
    name, 
    is_public, 
    display_order, 
    organization,
    created_at, 
    update_at as updated_at
from source_prod.leadingreach.contact_tag