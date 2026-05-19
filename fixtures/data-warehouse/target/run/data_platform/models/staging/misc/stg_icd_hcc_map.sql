
  create or replace   view dw_dev.dev_jkizer_staging.stg_icd_hcc_map
  
  copy grants
  
  
  as (
    select
	*
from source_prod.misc.icd_hcc_map
  );

