
    
    

with child as (
    select schedule_block_skey as from_field
    from dw_dev.dev_jkizer.fct_schedule_block_appointment
    where schedule_block_skey is not null
),

parent as (
    select schedule_block_skey as to_field
    from dw_dev.dev_jkizer.fct_schedule_block
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


