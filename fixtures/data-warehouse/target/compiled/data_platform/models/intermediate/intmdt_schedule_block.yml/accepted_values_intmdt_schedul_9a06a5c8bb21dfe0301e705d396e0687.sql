
    
    

with all_values as (

    select
        block_source as value_field,
        count(*) as n_records

    from dw_dev.dev_jkizer.intmdt_schedule_block
    group by block_source

)

select *
from all_values
where value_field not in (
    'recurring','other_event'
)


