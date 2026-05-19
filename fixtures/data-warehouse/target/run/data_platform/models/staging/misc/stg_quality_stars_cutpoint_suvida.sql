
  create or replace   view dw_dev.dev_jkizer_staging.stg_quality_stars_cutpoint_suvida
  
  copy grants
  
  
  as (
    select 
    measure_year,
    measure_source,
    quality_measure,
    star_score,
    cutpoint_value,
from dw_dev.dev_jkizer_source.map_quality_stars_eoy_cutpoint_suvida
  );

