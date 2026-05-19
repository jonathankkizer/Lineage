
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select zentake_response_skey
from dw_dev.dev_jkizer.zentake_response
where zentake_response_skey is null



  
  
      
    ) dbt_internal_test