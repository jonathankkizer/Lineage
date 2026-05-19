
  create or replace   view dw_dev.dev_jkizer_staging.stg_hcc_reference
  
  copy grants
  
  
  as (
    select
	*
from source_prod.misc.hcc_reference
  );

