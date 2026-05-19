
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select category
from dw_dev.dev_jkizer.fct_consent
where category is null



  
  
      
    ) dbt_internal_test