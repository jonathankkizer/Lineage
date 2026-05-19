
    
    

select
    custom_block_snapshot_skey as unique_field,
    count(*) as n_records

from dw_dev.dev_jkizer.dim_elation_custom_block_snapshot
where custom_block_snapshot_skey is not null
group by custom_block_snapshot_skey
having count(*) > 1


