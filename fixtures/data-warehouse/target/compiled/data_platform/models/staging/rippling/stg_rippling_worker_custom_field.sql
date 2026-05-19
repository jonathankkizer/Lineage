select
    worker_id,
    index,
    name,
    type,
    value,
    _fivetran_deleted,
    _fivetran_synced

from fivetran_source_prod.rippling.worker_custom_field