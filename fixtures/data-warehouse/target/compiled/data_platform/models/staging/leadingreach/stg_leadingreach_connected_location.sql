select 
    id as location_id, 
    type as location_type, 
    is_default, 
    name as location_name, 
    description, 
    timezone, 
    organization
from source_prod.leadingreach.connected_location