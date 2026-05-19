select
    id,
    created_at,
    updated_at,
    name,
    address_type,
    address_street_address,
    address_locality,
    address_region,
    address_postal_code,
    address_country,
    address_formatted,
    _fivetran_deleted,
    _fivetran_synced

from fivetran_source_prod.rippling.work_location