
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select question_concept
from dw_dev.dev_jkizer.fct_form_response
where question_concept is null



  
  
      
    ) dbt_internal_test