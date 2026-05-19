
  create or replace   view dw_dev.dev_jkizer_staging.stg_quality_stars_cutpoint_glidepath
  
  copy grants
  
  
  as (
    select 
    quality_measure,
    star_weight,
    star_score,
    star_score_cutpoint,
    glidepath_month,
from dw_dev.dev_jkizer_source.map_quality_stars_cutpoint_glidepath
  );

