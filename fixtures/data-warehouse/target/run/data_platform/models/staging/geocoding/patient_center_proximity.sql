
  create or replace   view dw_dev.dev_jkizer_staging.patient_center_proximity
  
  copy grants
  
  
  as (
    select
	*
from source_prod.geocoding.patient_center_proximity pcp
  );

