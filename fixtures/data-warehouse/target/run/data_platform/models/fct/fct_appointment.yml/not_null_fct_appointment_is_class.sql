
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select is_class
from dw_dev.dev_jkizer.fct_appointment
where is_class is null



  
  
      
    ) dbt_internal_test