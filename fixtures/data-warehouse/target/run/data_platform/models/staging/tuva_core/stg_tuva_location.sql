
  create or replace   view dw_dev.dev_jkizer_staging.stg_tuva_location
  
  copy grants
  
  
  as (
    select
	location_id,
	npi,
	name,
	facility_type,
	parent_organization,
	address,
	city,
	state,
	zip_code,
	latitude,
	longitude,
	data_source,
	tuva_last_run,
from suvida_tuva.core.location
  );

