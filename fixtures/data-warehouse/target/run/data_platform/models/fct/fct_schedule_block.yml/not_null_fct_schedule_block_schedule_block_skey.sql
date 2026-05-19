
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select schedule_block_skey
from dw_dev.dev_jkizer.fct_schedule_block
where schedule_block_skey is null



  
  
      
    ) dbt_internal_test