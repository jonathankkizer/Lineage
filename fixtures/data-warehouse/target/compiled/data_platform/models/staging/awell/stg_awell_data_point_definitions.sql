select 
    id as data_point_definition_id,
    definition_id,
    release_id,
    source_definition_id,
    category,
    key,
    options,
    value_type,
    date(last_synced_at) as last_synced_at
from source_prod.awell.data_point_definitions