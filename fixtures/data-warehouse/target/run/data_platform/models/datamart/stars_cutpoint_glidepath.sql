
  
    

create or replace transient table dw_dev.dev_jkizer.stars_cutpoint_glidepath
    copy grants
    
    
    as (-- Monthly glidepath cutpoints for progress tracking (universal across payers)
select
    glidepath_month,
    measure_name as quality_measure,
    star_2,
    star_3,
    star_4,
    star_5,
    star_6,
    -- Get weight from any payer (glidepath is universal, so pick first)
    coalesce(
        (select max(weight)
         from dw_dev.dev_jkizer_staging.stg_star_measure_weights w
         where w.measure_year = g.measure_year
         and w.measure_name = g.measure_name),
        0
    ) as star_weight
from dw_dev.dev_jkizer_staging.stg_star_cutpoints_glidepath g
    )
;


  