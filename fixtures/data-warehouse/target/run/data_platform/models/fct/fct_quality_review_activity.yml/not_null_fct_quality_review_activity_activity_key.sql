
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select activity_key
from dw_dev.dev_jkizer.fct_quality_review_activity
where activity_key is null



  
  
      
    ) dbt_internal_test