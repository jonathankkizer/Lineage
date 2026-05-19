
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select activity_id
from dw_dev.dev_jkizer.fct_awell_user_activity
where activity_id is null



  
  
      
    ) dbt_internal_test