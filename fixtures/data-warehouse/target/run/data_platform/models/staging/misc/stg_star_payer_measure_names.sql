
  
    

create or replace transient table dw_dev.dev_jkizer_staging.stg_star_payer_measure_names
    copy grants
    
    
    as (

with name_mapping as (
    select
        payer_name,
        payer_measure_name,
        -- Standardize measure names (replace em-dashes and en-dashes with hyphens)
        replace(replace(trim(measure_name), '—', '-'), '–', '-') as measure_name
    from dw_dev.dev_jkizer_source.star_payer_measure_names
),

latest_weights as (
    select
        measure_name,
        payer_name,
        weight
    from dw_dev.dev_jkizer_staging.stg_star_measure_weights
    qualify row_number() over (partition by measure_name, payer_name order by measure_year desc) = 1
)

select
    nm.payer_name,
    nm.payer_measure_name,
    nm.measure_name as quality_measure,
    sm.measure_type as quality_measure_type,
    coalesce(w.weight, 0) as measure_weight,
    sm.measure_abbreviation as abbreviations,
    sm.description,
    sm.measure_display_name
from name_mapping nm
left join dw_dev.dev_jkizer_staging.stg_star_measures sm
    on nm.measure_name = sm.measure_name
left join latest_weights w
    on nm.measure_name = w.measure_name
    and nm.payer_name = w.payer_name
    )
;


  