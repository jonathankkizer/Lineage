
  create or replace   view dw_dev.dev_jkizer_staging.stg_nppes_provider
  
  copy grants
  
  
  as (
    select
	*
from dw_prod.terminology.provider
  );

