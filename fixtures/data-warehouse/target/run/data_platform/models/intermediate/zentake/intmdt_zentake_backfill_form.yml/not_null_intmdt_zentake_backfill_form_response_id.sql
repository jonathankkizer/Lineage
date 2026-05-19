
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select response_id
from dw_dev.dev_jkizer.intmdt_zentake_backfill_form
where response_id is null



  
  
      
    ) dbt_internal_test