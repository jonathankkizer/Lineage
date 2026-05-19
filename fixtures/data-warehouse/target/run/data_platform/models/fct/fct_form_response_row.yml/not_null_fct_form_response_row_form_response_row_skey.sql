
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select form_response_row_skey
from dw_dev.dev_jkizer.fct_form_response_row
where form_response_row_skey is null



  
  
      
    ) dbt_internal_test