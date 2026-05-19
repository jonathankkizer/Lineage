
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select row_position
from dw_dev.dev_jkizer.fct_form_response_row
where row_position is null



  
  
      
    ) dbt_internal_test