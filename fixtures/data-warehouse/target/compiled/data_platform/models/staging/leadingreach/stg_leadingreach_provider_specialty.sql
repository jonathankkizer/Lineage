select 
    provider_id, 
    id as provider_specialty_id, 
    code,
    grouping,
    classification, 
    specialization,
    display_name
from source_prod.leadingreach.provider_specialty