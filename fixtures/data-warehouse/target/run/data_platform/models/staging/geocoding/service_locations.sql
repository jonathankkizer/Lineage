
  create or replace   view dw_dev.dev_jkizer_staging.service_locations
  
  copy grants
  
  
  as (
    select
	*
from source_prod.geocoding.service_locations pcp
  );

