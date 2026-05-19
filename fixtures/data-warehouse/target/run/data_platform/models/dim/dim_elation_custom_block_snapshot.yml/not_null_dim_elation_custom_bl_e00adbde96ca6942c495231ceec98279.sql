
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select custom_block_snapshot_skey
from dw_dev.dev_jkizer.dim_elation_custom_block_snapshot
where custom_block_snapshot_skey is null



  
  
      
    ) dbt_internal_test