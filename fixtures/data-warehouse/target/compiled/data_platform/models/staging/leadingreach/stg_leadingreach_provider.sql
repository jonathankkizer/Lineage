select 
    id as provider_id, 
    npi,
    is_no_npi_number, 
    first_name,
    last_name, 
    name_prefix,
    name_suffix,
    created_at,
    updated_at,
    organization,
    default_location
from source_prod.leadingreach.provider