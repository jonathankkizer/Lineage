







with validation as (
  select
    
    sum(case when suvida_id is null then 0 else 1 end) / cast(count(*) as numeric) as not_null_proportion
  from dw_dev.dev_jkizer.fct_quality_measure
  
),
validation_errors as (
  select
    
    not_null_proportion
  from validation
  where not_null_proportion < 0.99 or not_null_proportion > 1
)
select
  *
from validation_errors

