
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select flowroute_skey
from dw_dev.dev_jkizer.flowroute_calls
where flowroute_skey is null



  
  
      
    ) dbt_internal_test