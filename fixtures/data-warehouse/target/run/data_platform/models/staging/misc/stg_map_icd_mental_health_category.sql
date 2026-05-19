
  create or replace   view dw_dev.dev_jkizer_staging.stg_map_icd_mental_health_category
  
  copy grants
  
  
  as (
    select
    icd_10_code,
    listagg(distinct mental_health_abbreviation, ' | ') as mental_health_abbreviation,
    listagg(distinct mental_health_description, ' | ') as mental_health_description
from dw_dev.dev_jkizer_source.map_icd_mental_health_category
group by icd_10_code
  );

