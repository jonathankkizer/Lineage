
  create or replace   view dw_dev.dev_jkizer_staging.stg_tbl_prod_elation_health_unfulfilled_care_gaps
  
  copy grants
  
  
  as (
    select
	*
from source_prod.misc.tbl_prod_elation_health_unfulfilled_care_gaps
  );

