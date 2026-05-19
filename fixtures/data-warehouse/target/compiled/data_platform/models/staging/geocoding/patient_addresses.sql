select
	*,
	row_number() over (partition by suvida_id, source, address_id, address_line_1_key, address_line_2_key, city_key, state_key, zip_key order by date_created desc) as _idx
from source_prod.geocoding.patient_addresses