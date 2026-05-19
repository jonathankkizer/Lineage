
    
    

select
    schedule_block_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.fct_schedule_block
where schedule_block_skey is not null
group by schedule_block_skey
having count(*) > 1


