
  create or replace   view dw_dev.dev_jkizer_staging.stg_compas_usage_log
  
  copy grants
  
  
  as (
    select
	*
from source_prod.compas.src_compas_usage_logs
  );

