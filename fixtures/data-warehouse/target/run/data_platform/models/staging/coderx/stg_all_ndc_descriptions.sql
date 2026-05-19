
  create or replace   view dw_dev.dev_jkizer_staging.stg_all_ndc_descriptions
  
  copy grants
  
  
  as (
    select 
	*
from source_prod.coderx.all_ndc_descriptions
  );

