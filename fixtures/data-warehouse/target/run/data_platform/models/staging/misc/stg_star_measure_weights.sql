
  create or replace   view dw_dev.dev_jkizer_staging.stg_star_measure_weights
  
  copy grants
  
  
  as (
    select
    measure_year::int as measure_year,
    payer_name,
    measure_name,
    weight::decimal(5,2) as weight
from dw_dev.dev_jkizer_source.star_measure_weights
  );

