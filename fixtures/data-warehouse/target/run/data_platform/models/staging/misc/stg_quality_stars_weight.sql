
  create or replace   view dw_dev.dev_jkizer_staging.stg_quality_stars_weight
  
  copy grants
  
  
  as (
    select
	*
from dw_dev.dev_jkizer_source.map_quality_stars_weight
  );

