
    
    

with all_values as (

    select
        match_method as value_field,
        count(*) as n_records

    from dw_dev.dev_jkizer.fct_schedule_block_appointment
    group by match_method

)

select *
from all_values
where value_field not in (
    'time_overlap','native_link'
)


