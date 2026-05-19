select
    id,
    updated_at,
    name,
    legal_name,
    doing_business_as_name,
    _fivetran_deleted,
    _fivetran_synced

from fivetran_source_prod.rippling.company