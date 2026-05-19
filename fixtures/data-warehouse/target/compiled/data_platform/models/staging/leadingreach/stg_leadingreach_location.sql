select 
    id as location_id, 
    type as location_type, 
    is_default, 
    name, 
    description, 
    timezone, 
    organization 
from source_prod.leadingreach.location