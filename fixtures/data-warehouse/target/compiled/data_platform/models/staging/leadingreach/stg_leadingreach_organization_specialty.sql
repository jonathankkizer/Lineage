select
    organization_id, 
    id as organization_specialty_id, 
    code, 
    grouping, 
    classification, 
    specialization, 
    display_name, 
    phones,
    specialties
from source_prod.leadingreach.organization_specialty