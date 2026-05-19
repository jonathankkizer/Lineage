
  create or replace   view dw_dev.dev_jkizer_staging.stg_elation_health_care_gap_definition
  
  copy grants
  
  
  as (
    select
	*
from source_prod.caregaps.src_elation_health_care_gap_definition
  );

