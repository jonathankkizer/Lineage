select 
    organization_id, 
    id as specialty_id, 
    code, 
    grouping,
    classification, 
    specialization, 
    display_name, 
    phones, 
    specialties
from source_prod.leadingreach.connected_organization_specialty