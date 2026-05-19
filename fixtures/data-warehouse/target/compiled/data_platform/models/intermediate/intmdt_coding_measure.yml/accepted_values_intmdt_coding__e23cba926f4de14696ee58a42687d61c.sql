
    
    

with all_values as (

    select
        measure_status as value_field,
        count(*) as n_records

    from dw_dev.dev_jkizer.intmdt_coding_measure
    group by measure_status

)

select *
from all_values
where value_field not in (
    'closed','open','suspect'
)


