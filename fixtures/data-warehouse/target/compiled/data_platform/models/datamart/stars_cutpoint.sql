-- Payer-specific end-of-year cutpoints (excludes Suvida stretch goals)
select
    c.measure_year,
    c.payer_name as measure_source,
    coalesce(sm.measure_display_name, c.measure_name) as quality_measure,
    c.star_2,
    c.star_3,
    c.star_4,
    c.star_4_5,
    c.star_5,
    c.star_6,
    coalesce(w.weight, 0) as star_weight
from dw_dev.dev_jkizer_staging.stg_star_cutpoints_eoy c
left join dw_dev.dev_jkizer_staging.stg_star_measures sm
    on c.measure_name = sm.measure_name
left join dw_dev.dev_jkizer_staging.stg_star_measure_weights w
    on c.measure_year = w.measure_year
    and c.payer_name = w.payer_name
    and c.measure_name = w.measure_name
where c.payer_name != 'Suvida'  -- Standard payer cutpoints only