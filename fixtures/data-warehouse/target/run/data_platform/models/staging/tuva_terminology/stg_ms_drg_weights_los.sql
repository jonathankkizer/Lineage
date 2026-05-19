
  create or replace   view dw_dev.dev_jkizer_staging.stg_ms_drg_weights_los
  
  copy grants
  
  
  as (
    select
	*
from dw_prod.terminology.ms_drg_weights_los
  );

