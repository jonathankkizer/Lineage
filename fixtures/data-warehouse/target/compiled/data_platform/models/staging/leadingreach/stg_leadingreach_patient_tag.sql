select 
    patient_id, 
    id as patient_tag_id, 
    type, 
    color,
    name,
    is_public, 
    display_order,
    organization,
    created_at,
    updated_at
from source_prod.leadingreach.patient_tag