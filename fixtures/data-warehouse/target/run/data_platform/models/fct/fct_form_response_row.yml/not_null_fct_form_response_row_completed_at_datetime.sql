
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select completed_at_datetime
from dw_dev.dev_jkizer.fct_form_response_row
where completed_at_datetime is null



  
  
      
    ) dbt_internal_test