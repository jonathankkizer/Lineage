
  
    

create or replace transient table dw_dev.dev_jkizer.dim_location
    copy grants
    
    
    as (select
	service_location_id as location_id,
	service_location_name as location_name,
	address as location_address_1,
	suite as location_address_2,
	city as location_city,
	state as location_state,
	zip as location_zip,
	phone as location_phone,
	fax as location_fax,
	concat(address, ', ', city, ', ', state, ' ', zip) as freeform_address,
	deletion_datetime
	-- can pull in other location-level dimensions (e.g., center director, location facilities, etc.)
from dw_dev.dev_jkizer_staging.stg_elation_service_location
where _idx = 1
    )
;


  