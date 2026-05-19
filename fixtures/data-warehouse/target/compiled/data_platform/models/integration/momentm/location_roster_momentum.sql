select
    lctn.location_name,
    'CLINIC' as location_type,
    sl.street_number,
    sl.street_name,
    lctn.location_address_2 as unit,
    sl.city,
    sl.state,
    sl.zip,
    sl.longitude,
    sl.latitude,
    'yes' as is_geocoded,
    null as comments,
    null as c_first_name,
    null as c_last_name,
    lctn.location_phone
from dw_dev.dev_jkizer.dim_location lctn
inner join dw_dev.dev_jkizer_staging.service_locations sl
    on lctn.location_id = sl.elation_id