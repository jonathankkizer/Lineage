-- Suvida stretch goal cutpoints (most aggressive across all payers)
select
    c.measure_year,
    coalesce(sm.measure_display_name, c.measure_name) as quality_measure,
    c.star_2,
    c.star_3,
    c.star_4,
    c.star_4_5,
    c.star_5,
    c.star_6,
    -- Use Suvida-specific weight if defined, otherwise fall back to max across payers
    coalesce(
      (select coalesce(max(iff(payer_name = 'Suvida', weight, null)), max(weight))
       from dw_dev.dev_jkizer_staging.stg_star_measure_weights w
       where w.measure_year = c.measure_year
       and w.measure_name = c.measure_name),
      0
  ) as star_weight
from dw_dev.dev_jkizer_staging.stg_star_cutpoints_eoy c
left join dw_dev.dev_jkizer_staging.stg_star_measures sm
    on c.measure_name = sm.measure_name
where c.payer_name = 'Suvida'  -- Suvida stretch goals only