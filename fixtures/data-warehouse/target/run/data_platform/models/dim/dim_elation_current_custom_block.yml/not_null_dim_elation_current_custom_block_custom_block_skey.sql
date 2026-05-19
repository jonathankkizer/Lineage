
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select custom_block_skey
from dw_dev.dev_jkizer.dim_elation_current_custom_block
where custom_block_skey is null



  
  
      
    ) dbt_internal_test